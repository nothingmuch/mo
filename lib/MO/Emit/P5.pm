#!/usr/bin/perl

package MO::Emit::P5;
use Moose;

sub responder_interface_to_package {
	my ( $self, %params ) = @_;

	die "Dunno how to emit $params{responder_interface}" unless $params{responder_interface}->isa("MO::Run::ResponderInterface::MethodTable");

	$self->method_table_to_package( %params );
}

sub method_table_to_package {
	my ( $self, %params ) = @_;
	my ( $method_table, $package ) = @params{qw/responder_interface package/};

	my $methods = $method_table->methods;

	foreach my $method_name ( keys %$methods ) {
		no strict 'refs';
		*{ join("::", $package,  $method_name ) } = $methods->{$method_name}->body;
	}
}

__PACKAGE__;

__END__
