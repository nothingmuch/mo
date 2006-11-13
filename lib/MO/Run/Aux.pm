#!/usr/bin/perl

package MO::Run::Aux;

use strict;
use warnings;

use MO::Run::Responder::Invocant;
use MO::Run::Invocation::Method;
use MO::Run::Aux::Stack;

use Scalar::Util qw/blessed/;

use Tie::RefHash;

use Sub::Exporter -setup => {
	exports => [qw/box unbox_value stack method_call/],
};

our $MO_NATIVE_RUNTIME                 = $ENV{MO_NATIVE_RUNTIME};
our $MO_NATIVE_RUNTIME_NO_INDIRECT_BOX = $ENV{MO_NATIVE_RUNTIME_NO_INDIRECT_BOX};
our $STACK;
our $PACKAGE_SEQUENCE = "A";
our $REGISTRY;

sub _responder_interface_to_package {
	my $responder_interface = shift;

	return registry()->autovivify_class( $responder_interface->origin );
}

sub _generate_package_name { "MO::Run::Aux::ANON_" . $PACKAGE_SEQUENCE++ }

sub _setup_registry {
	require MO::P5::Registry;
	MO::P5::Registry->new;
}

sub registry {
	$REGISTRY ||= _setup_registry();
}

sub box ($$) {
	my ( $instance, $responder_interface ) = @_;

	if ( $MO_NATIVE_RUNTIME ) {
		my $pkg = _responder_interface_to_package($responder_interface);

		local $@;
		if ( eval { $instance->does("MO::Compile::Origin") } ) {
			return $pkg;
		} else {
			my $box = $MO_NATIVE_RUNTIME_NO_INDIRECT_BOX
				? $instance
				: \$instance;

			return bless $box, $pkg;
		}
	} else {
		MO::Run::Responder::Invocant->new(
			invocant => $instance,
			responder_interface => $responder_interface,
		);
	}
}

sub unbox_value ($) {
	my $responder = shift;

	if ( $MO_NATIVE_RUNTIME ) {
		if ( ref $responder ) {
			if ( $MO_NATIVE_RUNTIME_NO_INDIRECT_BOX ) {
				return $responder;
			} else {
				return $$responder;
			}
		} else {
			return $REGISTRY->class_of_package( $responder );
		}
	} else {
		return $responder->invocant;
	}
}

sub stack (;@) {
	if ( @_ ) {
		return $STACK = shift;
	} else {
		return $STACK ||= MO::Run::Aux::Stack->new;
	}
}

sub method_call ($$;@) {
	my ( $invocant, $method, @arguments ) = @_;

	if ( $MO_NATIVE_RUNTIME ) {
		return $invocant->$method( @arguments );
	} else {
		my $ri;

		if ( blessed($arguments[0]) and $arguments[0]->can("does") and $arguments[0]->does("MO::Run::Abstract::ResponderInterface") ) {
			$ri = shift @arguments;
		} else {
			$ri = $invocant->responder_interface;
		}

		if ( ref $method ) {
			# FIXME the responder interface should take care of this
			my $body = $method->body;
			$invocant->$body( @arguments );
		} else {
			my $thunk = $ri->dispatch(
				$invocant,
				MO::Run::Invocation::Method->new(
					name      => $method,
					arguments => \@arguments,
				),
				stack => stack(),
			);

			die "No such method: $method on inv $invocant" unless $thunk;

			return $thunk->();
		}
	}
}

sub caller {
	if ( $MO_NATIVE_RUNTIME ) {
		my $package = ( CORE::caller(shift || 0 + 1) )[0];

		if ( my $class = $REGISTRY->class_of_package( $package ) ) {
			return $class;
		} else {
			return $package;
		}
	} else {
		return stack()->tail;
	}
}

__PACKAGE__;

__END__
