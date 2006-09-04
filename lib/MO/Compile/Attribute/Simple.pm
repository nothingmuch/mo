#!/usr/bin/perl

package MO::Compile::Attribute::Simple;
use Moose;

use MO::Compile::Attribute::Simple::Compiled;
use MO::Compile::Field::Simple;
use MO::Run::MethodDefinition::Simple;

has name => (
	isa => "Str",
	is  => "rw",
	required => 1,
);

has accessor_name => (
	isa => "Str",
	is  => "rw",
	lazy    => 1,
	default => sub { $_[0]->name },
);

has private => (
	isa => "Bool",
	is  => "ro",
	default => 0,
);

sub fields {
	my ( $self, $class ) = @_;

	return MO::Compile::Field::Simple->new(
		name      => $self->name,
		private   => $self->private,
		class     => $class,
		attribute => $self,
	);
}

sub compile {
	my ( $self, %params ) = @_;

	return MO::Compile::Attribute::Simple::Compiled->new(
		attribute => $self,
		%params,
	);
}	

__PACKAGE__;

__END__
