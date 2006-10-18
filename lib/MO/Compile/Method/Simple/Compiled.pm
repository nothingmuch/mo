#!/usr/bin/perl

package MO::Compile::Method::Simple::Compiled;
use Moose;

extends "MO::Compile::Method::Compiled";

has body => (
	isa => "CodeRef",
	is  => "rw",
);

__PACKAGE__;

__END__
