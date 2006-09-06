#!/usr/bin/perl

package MO::Compile::Method::Simple;
use Moose;

with "MO::Compile::Method";

use MO::Compile::Method::Definition;

sub name {}
has name => (
	isa => "Str",
	is  => "ro",
	required => 1,
);

sub definition {}
has definition => (
	isa => "MO::Compile::Method::Definition",
	is  => "ro",
	coerce   => 1,
	required => 1,
);

__PACKAGE__;

__END__
