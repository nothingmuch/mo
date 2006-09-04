#!/usr/bin/perl

package MO::Compile::Field::Simple;
use Moose;

has name => (
	isa => "Str",
	is  => "ro",
	required => 1,
);

has private => (
	isa => "Bool",
	is  => "ro",
	required => 1,
);

has class => (
	does => "MO::Compile::Class",
	is   => "ro",
	required => 1,
);

has attribute => (
	isa => "MO::Compile::Attribute::Simple",
	is  => "ro",
	required => 1,
);

__PACKAGE__;

__END__
