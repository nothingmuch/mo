#!/usr/bin/perl

package MO::Compile::Field::Simple;
use Moose;

has name => (
	isa => "Str",
	is  => "ro",
);

has attribute => (
	isa => "MO::Compile::Attribute::Simple",
	is  => "ro",
);

__PACKAGE__;

__END__
