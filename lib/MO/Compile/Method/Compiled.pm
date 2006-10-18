#!/usr/bin/perl

package MO::Compile::Method::Compiled;
use Moose;
use Moose::Util::TypeConstraints;

coerce "MO::Compile::Method::Compiled" => (
	from "CodeRef" => via {
		require MO::Compile::Method::Simple::Compiled;
		MO::Compile::Method::Simple::Compiled->new( body => $_[0] )
	},
);

__PACKAGE__;

__END__
