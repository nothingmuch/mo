#!/usr/bin/perl

package MO::Compile::Method::Simple;
use Moose;

with "MO::Compile::Method";

use MO::Compile::Method::Compiled;

sub name {}
has name => (
	isa => "Str",
	is  => "ro",
	required => 1,
);

has definition => (
	isa => "MO::Compile::Method::Compiled",
	is  => "ro",
	coerce   => 1,
	required => 1,
);

sub compile {
	my ( $self, %params ) = @_;
	$self->definition;
}

__PACKAGE__;

__END__
