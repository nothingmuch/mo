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
	foreach my $method ( keys %$class, %$instance ) {
		$methods{$method} ||= $self->merge_class_and_instance_method(
			$method,
			$class->{$method},
			$instance->{$method},
			%params,
		);
	}

	return \%methods;
}

# FIXME cache?
sub merge_class_and_instance_method {
	my ( $self, $name, $class, $instance, %params ) = @_;

	$class    ||= sub { croak "The method '$name' can only be used as an instance method" };
	$instance ||= sub { croak "The method '$name' can only be used as a class method" };

	sub { goto ref($_[0]) ? $instance : $class };
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
	my ( $hash, $package ) = @params{qw/hash package/};

	my $class = $params{class};

	my @isa = map { $params{registry}->autovivify_class($_) } $class->superclasses;

	$package->add_package_symbol( '@ISA', \@isa );

	foreach my $method ( keys %$hash ) {
		$package->add_package_symbol( '&'. $method, $hash->{$method} );
	}
}

sub method_table_to_cv_hash {
	my ( $self, %params ) = @_;
	my ( $method_table) = @params{qw/responder_interface/};

	my $methods = $method_table->methods;

	my %methods;

	@methods{ keys %$methods } = map { $_->body } values %$methods;

	return \%methods;
}

__PACKAGE__;

__END__
