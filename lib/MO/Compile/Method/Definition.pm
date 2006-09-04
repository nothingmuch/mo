#!/usr/bin/perl

package MO::Compile::Method::Definition;
use Moose;
use Moose::Util::TypeConstraints;

coerce "MO::Compile::Method::Definition" => (
	from "CodeRef" => via {
		require MO::Run::MethodDefinition::Simple;
		MO::Run::MethodDefinition::Simple->new( body => $_[0] )
	},
);

__PACKAGE__;

__END__
