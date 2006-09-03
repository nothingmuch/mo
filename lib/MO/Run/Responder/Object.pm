#!/usr/bin/perl

package MO::Run::Responder::Object;
use Moose;

with "MO::Run::Abstract::Responder";

has object => (
	isa => "Any",
	is  => "rw",
);

has responder_interface => (
	does => "MO::Run::Abstract::ResponderInterface",
	is   => "rw",
);

__PACKAGE__;

__END__

