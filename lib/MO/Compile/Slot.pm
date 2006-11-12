#!/usr/bin/perl

package MO::Compile::Slot;
use Moose::Role;

requires "field";

requires "construct";

requires "initialize";

requires "set_value";

requires "get_value";

requires "is_initialized";

requires "clear";

sub initialize_and_set_value {
	my ( $self, $instance, $value ) = @_;
	$self->initialize( $instance ) unless $self->is_initialized( $instance );
	$self->set_value( $instance, $value );
}

__PACKAGE__;

__END__
