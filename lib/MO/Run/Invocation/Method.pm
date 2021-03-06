#!/usr/bin/perl

package MO::Run::Invocation::Method;
use Moose;

with "MO::Run::Abstract::Invocation";

has name => (
	isa => "Str",
	is  => "rw",
);

has arguments => (
	isa => "ArrayRef",
	is  => "rw",
	auto_deref => 1,
);

__PACKAGE__;

__END__
