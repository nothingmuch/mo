#!/usr/bin/perl

package MO::Compile::Attribute::Simple;
use Moose;

use MO::Run::Attribute::Simple;
use MO::Compile::Field::Simple;
use MO::Run::Method::Simple;

has name => (
	isa => "Str",
	is  => "rw",
	required => 1,
);

sub fields {
	my ( $self, $class ) = @_;

	return MO::Compile::Field::Simple->new(
		name      => $self->name,
		attribute => $self,
	);
}

sub compile {
	my ( $self, %params ) = @_;

	return MO::Run::Attribute::Simple->new(
		attribute => $self,
		%params,
	);
}	

__PACKAGE__;

__END__
