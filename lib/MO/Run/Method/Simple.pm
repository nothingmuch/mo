#!/usr/bin/perl

package MO::Run::Method::Simple;
use Moose;

has body => (
	isa => "CodeRef",
	is  => "rw",
);

__PACKAGE__;

__END__
