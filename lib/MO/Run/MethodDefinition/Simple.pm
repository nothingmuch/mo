#!/usr/bin/perl

package MO::Run::MethodDefinition::Simple;
use Moose;

extends "MO::Compile::Method::Definition";

has body => (
	isa => "CodeRef",
	is  => "rw",
);

__PACKAGE__;

__END__
