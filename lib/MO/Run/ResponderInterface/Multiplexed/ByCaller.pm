#!/usr/bin/perl

package MO::Run::ResponderInterface::Multiplexed::ByCaller;
use Moose;

with "MO::Run::ResponderInterface::Multiplexed";

has per_caller_interfaces => (
	isa => "HashRef",
	is  => "rw",
	required => 1,
);

sub fallback_interface {}
has fallback_interface => (
	does => "MO::Run::Abstract::ResponderInterface",
	is   => "rw",
	required => 1,
);

sub interface_for_caller {
	my ( $self, $caller ) = @_;
	$self->per_caller_interfaces->{$caller};
}

sub interface_for {
	my ( $self, $responder, $inv ) = @_;

	if ( my $caller = $inv->caller ) {
		return $self->interface_for_caller( $caller );
	}

	return;
}

__PACKAGE__;

__END__
