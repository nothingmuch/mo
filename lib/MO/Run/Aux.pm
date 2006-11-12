#!/usr/bin/perl

package MO::Run::Aux;

use strict;
use warnings;

use MO::Run::Aux::Stack;

use Scalar::Util qw/blessed/;

use Tie::RefHash;

use Sub::Exporter -setup => {
	exports => [qw/box unbox_value stack method_call/],
};

our $MO_NATIVE_RUNTIME                 = $ENV{MO_NATIVE_RUNTIME};
our $MO_NATIVE_RUNTIME_NO_INDIRECT_BOX = $ENV{MO_NATIVE_RUNTIME_NO_INDIRECT_BOX};
our $STACK;
our $EMITTER;
our $PACKAGE_SEQUENCE = "A";
tie our %RI_TO_PKG, 'Tie::RefHash';

sub _responder_interface_to_package {
	my $responder_interface = shift;

	my $pkg = $RI_TO_PKG{$responder_interface} ||= "MO::Run::Aux::ANON_" . $PACKAGE_SEQUENCE++;

	$EMITTER ||= _setup_emitter();

	$EMITTER->responder_interface_to_package(
		responder_interface => $responder_interface,
		package             => $pkg,
	);

	return $pkg;
}

sub _setup_emitter {
	require MO::Emit::P5;
	MO::Emit::P5->new;
}

sub box ($$) {
	my ( $instance, $responder_interface ) = @_;

	if ( $MO_NATIVE_RUNTIME ) {
		my $pkg = _responder_interface_to_package($responder_interface);

		my $box = $MO_NATIVE_RUNTIME_NO_INDIRECT_BOX
			? $instance
			: \$instance;

		return bless $box, $pkg;
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
		if ( $MO_NATIVE_RUNTIME_NO_INDIRECT_BOX ) {
			return $responder;
		} else {
			return $$responder;
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

__PACKAGE__;

__END__
