#!/usr/bin/perl

package MO::Compile::Slot::Simple;
use Moose;

has name => (
	isa => "Str",
	is  => "ro",
);

sub get_value {
	my ( $self, $instance ) = @_;
	$instance->{ $self->name };
}

sub set_value {
	my ( $self, $instance, $value ) = @_;
	$instance->{ $self->name } = $value;
}

__PACKAGE__;

__END__
