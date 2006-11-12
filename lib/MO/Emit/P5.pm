#!/usr/bin/perl

package MO::Emit::P5;
use Moose;

sub responder_interface_to_package {
	my ( $self, %params ) = @_;

	if ( $params{responder_interface}->isa("MO::Run::ResponderInterface::Multiplexed::ByCaller") ) {
		$self->bycaller_to_package( %params );
	} else {
		die "Dunno how to emit $params{responder_interface}" unless $params{responder_interface}->isa("MO::Run::ResponderInterface::MethodTable");

		$self->method_table_to_package( %params );
	}
}

sub bycaller_to_package {
	my ( $self, @params ) = @_;

	my $hash = $self->bycaller_to_cv_hash( @params );

	$self->install_cv_hash( @params, hash => $hash );
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
		require Carp;
		sub {
			goto $caller_table->{MO::Run::Aux::caller() } ||
				Carp::croak qq{Can't locate object method "$name" via package "} . (ref($_[0]) || $_[0]) . '"';
		};
	}
}

sub _bycaller_register_table {
	my ( $self, $methods, $caller, $hash ) = @_;

	foreach my $method ( keys %$hash ) {
		$methods->{$method}{$caller} = $hash->{$method};
	}
}

sub method_table_to_package {
	my ( $self, @params ) = @_;

	my $hash = $self->method_table_to_cv_hash( @params );

	$self->install_cv_hash( @params, hash => $hash );
}

sub install_cv_hash {
	my ( $self, %params ) = @_;
	my ( $hash, $package ) = @params{qw/hash package/};

	foreach my $method ( keys %$hash ) {
		no strict 'refs';
		*{"${package}::${method}"} = $hash->{$method};
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
