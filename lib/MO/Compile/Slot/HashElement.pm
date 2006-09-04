#!/usr/bin/perl

package MO::Compile::Slot::HashElement;
use Moose;

has name => (
	isa => "Str",
	is  => "ro",
);

sub get_value {
	my ( $self, $instance ) = @_;
	$instance->{ $self->name };
}

sub initialize_and_set_value {
	my ( $self, $instance, $value ) = @_;
	$self->initialize( $instance ) unless $self->is_initialized( $instance );
	$self->set_value( $instance, $value );
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
