#!/usr/bin/perl

package MO::Run::Aux;

use strict;
use warnings;

use Scalar::Util qw/blessed/;

use Tie::RefHash;

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

sub _pre_box {
	my $ri = shift;

	if ( $MO_NATIVE_RUNTIME) {
		return _responder_interface_to_package($ri);
	} else {
		return $ri;
	}
}

sub box ($$) {
	my ( $instance, $responder_interface ) = @_;

	if ( $MO_NATIVE_RUNTIME ) {
		my $pkg = ref $responder_interface
			? _responder_interface_to_package($responder_interface)
			: $responder_interface;

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
		require MO::Run::Responder::Invocant;
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
		require MO::Run::Aux::Stack;
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
			require MO::Run::Invocation::Method;
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

sub compile_pmc {
	require Generate::PMC::File;
	require Data::Dump::Streamer;

	my ( $pkg, $file ) = CORE::caller();

	my $glob = do { no strict 'refs'; *{"::" . $pkg . "::"} };

	# indentation clashes with the prettier sub decls
	my $src = Data::Dump::Streamer::Dump($glob)->Indent(0)->Out;

	# we don't really need this
	$src =~ s{ \$VAR1 \s* = .*? \n \*{'::${pkg}::'} \s* = .*? ;\n }{}sx;

	# we already have a package decl, we don't need more
	$src =~ s{ ^ \* ${pkg}:: (\w+) \b }{*$1}gmx;

	# sub decls can be a bit prettier
	$src =~ s{ ^ \* ([\w:]+) \s* = \s* sub }{\nsub $1}gmx;

	Generate::PMC::File->new(
		input_file              => $file,
		include_freshness_check => 0,
		body                    => [ join "\n\n",
			"package $pkg;",
			'BEGIN { $MO::Run::Aux::MO_NATIVE_RUNTIME = 1 }',
			$src,
			'1;',
			'',
		],
	)->write_pmc();
}

__PACKAGE__;

__END__
