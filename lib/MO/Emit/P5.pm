#!/usr/bin/perl

package MO::Emit::P5;
use Moose;

use Carp qw/croak/;

# TODO
# @ISA
# 'can' is context sensitive
# optimize when @ISA and parent already contains the exact same method by the same name
# MRO within the responder interfaces
# (do they handle next, etc?)

sub emit_class {
	my ( $self, @params ) = @_;
	my $cv_hash = $self->class_to_cv_hash( @params );
	$cv_hash->{meta} = sub { MO::Run::Aux::registry()->class_of_package( ref $_[0] or $_[0] ) };
	$self->install_cv_hash( @params, hash => $cv_hash );
}

sub class_to_cv_hash {
	my ( $self, %params ) = @_;
	my $class = $params{class};

	my ( $class_interface, $instance_interface ) = map {
		$self->responder_interface_to_cv_hash(
			%params,
			responder_interface => $class->$_()
		);
	} qw/class_interface instance_interface/;
	
	return $self->merge_class_and_instance_interfaces(
		%params,
		class_interface    => $class_interface,
		instance_interface => $instance_interface,
	);
}

sub merge_class_and_instance_interfaces {
	my ( $self, %params ) = @_;
	my ( $class, $instance, $meta, $registry ) = @params{qw/class_interface instance_interface class registry/};

	my %methods;
	foreach my $method ( keys %$class, keys %$instance ) {
		$methods{$method} ||= $self->merge_class_and_instance_method(
			$method,
			$class->{$method},
			$instance->{$method},
			%params,
		);
	}

	return \%methods;
}

my %cache;

sub merge_class_and_instance_method {
	my ( $self, $name, $class_method, $instance_method, %params ) = @_;

	unless ( $class_method ) {
		return $cache{$instance_method} ||= eval q#sub {
			croak "The method '# . $name . q#' can only be used as an instance method" unless ref $_[0];
			goto $instance_method;
		}#;
	}

	unless ( $instance_method ) {
		return $cache{$class_method} ||= eval q#sub {
			croak "The method '# . $name . q#' can only be used as a class method" if ref $_[0];
			goto $class_method;
		}#;
	}

	return $cache{$instance_method . "/" . $class_method} ||= sub { goto ref($_[0]) ? $instance_method : $class_method };
}

sub responder_interface_to_cv_hash {
	my ( $self, %params ) = @_;

	if ( $params{responder_interface}->isa("MO::Run::ResponderInterface::Multiplexed::ByCaller") ) {
		return $self->bycaller_to_cv_hash( %params );
	} else {
		die "Dunno how to emit $params{responder_interface}" unless $params{responder_interface}->isa("MO::Run::ResponderInterface::MethodTable");
		return $self->method_table_to_cv_hash( %params );
	}
}

sub bycaller_to_cv_hash {
	my ( $self, %params ) = @_;
	my ( $bycaller, $package ) = @params{qw/responder_interface package/};

	my %methods;

	$self->_bycaller_register_table(
		\%methods,
		public => $self->method_table_to_cv_hash(
			responder_interface => $bycaller->fallback_interface,
		),
	);

	foreach my $caller ( keys %{ $bycaller->per_caller_interfaces } ) {
		$self->_bycaller_register_table(
			\%methods,
			$caller,
			$self->method_table_to_cv_hash(
				responder_interface => $bycaller->per_caller_interfaces->{$caller},
			),
		);
	}

	foreach my $method_name ( keys %methods ) {
		$methods{$method_name} = $self->merge_methods_by_caller( $method_name, $methods{$method_name} );
	}

	return \%methods;
}

sub merge_methods_by_caller {
	my ( $self, $name, $caller_table ) = @_;
	
	if ( my $public = delete $caller_table->{public} ) {
		sub { goto $caller_table->{MO::Run::Aux::caller()} || $public }
	} else {
		sub {
			goto $caller_table->{MO::Run::Aux::caller() } ||
				croak qq{Can't locate object method "$name" via package "} . (ref($_[0]) || $_[0]) . '"';
		};
	}
}

sub _bycaller_register_table {
	my ( $self, $methods, $caller, $hash ) = @_;

	foreach my $method ( keys %$hash ) {
		$methods->{$method}{$caller} = $hash->{$method};
	}
}

sub install_cv_hash {
	my ( $self, %params ) = @_;
	my ( $hash, $package_obj ) = @params{qw/hash package/};

	my $class = $params{class};

	my @isa = map { $params{registry}->autovivify_class($_) } $class->superclasses;

	$package_obj->add_package_symbol( '@ISA', \@isa );

	my $package = $package_obj->name;

	foreach my $method ( keys %$hash ) {
		my $inherited = $package->UNIVERSAL::can($method); # explicitly UNIVERSAL::can, since we care about native disptach
		next if $inherited and $inherited == $hash->{$method};
		$package_obj->add_package_symbol( '&'. $method, $hash->{$method} );
	}
}

sub method_table_to_cv_hash {
	my ( $self, %params ) = @_;
	my ( $method_table) = @params{qw/responder_interface/};

	my $methods = $method_table->methods;

	my %methods;

	@methods{ keys %$methods } = map { $self->method_to_cv($_) } values %$methods;

	return \%methods;
}

sub method_to_cv {
	my ( $self, $method ) = @_;

	if ( my $original = $method->method ) {
		if ( $original->isa("MO::Compile::Class::Method::Constructor") ) {
			if ( my $cv = $self->constructor_to_cv($original) ) {
				return $cv;
			}
		} elsif( $original->isa("MO::Compile::Class::Method::Accessor") ) {
			if ( my $cv = $self->accessor_to_cv($original) ) {
				return $cv;
			}
		}
	}

	return $method->body;
}

# inlined versions of std accessor and constructor

sub constructor_to_cv {
	my ( $self, $method ) = @_;

	my $layout = $method->layout;
	return unless $layout->isa("MO::Compile::Class::Layout::Hash");

	my @initializers = $method->initializers;
	return if grep { not $_->isa("MO::Compile::Attribute::Simple::Compiled") } @initializers;

	my $pkg = MO::Run::Aux::_pre_box($method->responder_interface);

	my @initializer_fields = map { $_->slot->name } @initializers;

	return $cache{$method} ||= eval q#sub {
		my ( $class, %params ) = @_;

		my $struct = {};

		@{ $struct }{qw(# . "@initializer_fields" . q#)} = @params{qw(# . "@initializer_fields" . q#)};

		return bless(
			( MO::Run::Aux::MO_NATIVE_RUNTIME_NO_INDIRECT_BOX ? $struct : \$struct ),
			$class
		);
	}# || die "error in eval: $@";
}

sub accessor_to_cv {
	my ( $self, $method ) = @_;

	my $slot = $method->slot;
	return unless $slot->isa("MO::Compile::Slot::HashElement");

	my $name = $slot->name;

	return $cache{"accessor:$name"} ||= eval q#sub {
		my ( $self, @args ) = @_;
		$self = $$self unless MO::Run::Aux::MO_NATIVE_RUNTIME_NO_INDIRECT_BOX;
		$self->{"# . $name . q#"} = $args[0] if @args;
		$self->{"# . $name . q#"};
	}# || die "error in eval: $@";
}

__PACKAGE__;

__END__
