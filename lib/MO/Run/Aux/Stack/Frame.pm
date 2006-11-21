#!/usr/bin/perl

package MO::Run::Aux::Stack::Frame;
use Moose;

has autopop => (
	isa => "Bool",
	is  => "ro",
	default => 1,
);

has stack => (
	isa => "MO::Run::Aux::Stack",
	is  => "ro",
	required => 1,
);

has item => (
	isa => "Any",
	is  => "rw",
	required => 1,
);

has debug => (
	isa => "Str",
	is  => "rw",
);

has _popped => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

sub DEMOLISH {
	my $self = shift;
	$self->pop if $self->autopop;
}

sub pop {
	my $self = shift;
	$self->stack->pop( $self ) unless $self->_popped;
}

__PACKAGE__;

__END__
