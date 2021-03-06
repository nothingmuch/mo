#!/usr/bin/perl

package MO::Run::ResponderInterface::Multiplexed;
use Moose::Role;

with "MO::Run::Abstract::ResponderInterface";

requires "fallback_interface";

requires "interface_for";

sub dispatch {
	my ( $self, $responder, $inv, @params ) = @_;

	# the maybe monad would be nice here ;-)
	if ( my $interface = $self->interface_for( $responder, $inv, @params ) ) {
		if ( my $match = $interface->dispatch( $responder, $inv, @params ) ) {
			return $match;
		}
	}

	return $self->dispatch_failed( $responder, $inv, @params );
}

sub dispatch_failed {
	my ( $self, $responder, $inv ) = @_;

	if ( my $fallback = $self->fallback_interface ) {
		return $fallback->dispatch( $responder, $inv );
	}

	return;
}


__PACKAGE__;

__END__
