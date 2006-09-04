#!/usr/bin/perl

package MO::Compile::Method::Simple;
use Moose;

use MO::Compile::Method::Definition;

has name => (
	isa => "Str",
	is  => "ro",
	required => 1,
);

has definition => (
	isa => "MO::Compile::Method::Definition",
	is  => "ro",
	coerce   => 1,
	required => 1,
);

__PACKAGE__;

__END__
