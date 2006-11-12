#!/usr/bin/perl

package MO::Compile::Slot::HashElement;
use Moose;

with "MO::Compile::Slot";

sub field {}
has field => (
	does => "MO::Compile::Field",
	is   => "ro",
	required => 1,
);

has name => (
	isa => "Str",
	is  => "ro",
);

sub get_value {
	my ( $self, $instance ) = @_;
	$instance->{ $self->name };
}

sub initialize {
	my ( $self, $instance ) = @_;
	\$instance->{ $self->name };
}

sub set_value {
	my ( $self, $instance, $value ) = @_;
	$instance->{ $self->name } = $value;
}

sub construct {
	my ( $self, $instance ) = @_;
	return;
}

sub is_initialized {
	my ( $self, $instance ) = @_;
	exists $instance->{ $self->name };
}

sub clear {
	my ( $self, $instance ) = @_;
	delete $instance->{ $self->name };
}

__PACKAGE__;

__END__
