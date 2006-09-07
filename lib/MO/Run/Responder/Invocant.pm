#!/usr/bin/perl

package MO::Run::Responder::Invocant;
use Moose;

with "MO::Run::Abstract::Responder";

has invocant => (
	isa => "Any",
	is  => "rw",
);

has responder_interface => (
	does => "MO::Run::Abstract::ResponderInterface",
	is   => "rw",
);

__PACKAGE__;

__END__

