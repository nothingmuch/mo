#!/usr/bin/perl

package MO::Compile::Field::Simple;
use Moose;

with "MO::Compile::Field";

sub name {}
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

has origin => (
	does => "MO::Compile::Origin",
	is   => "ro",
	required => 1,
);

has target => (
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
