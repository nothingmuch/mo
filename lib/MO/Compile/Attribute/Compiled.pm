#!/usr/bin/perl

package MO::Compile::Attribute::Compiled;
use Moose::Role;

requires "name";

requires "methods";

requires "slots";

requires "origin";

requires "target";

__PACKAGE__;

__END__
