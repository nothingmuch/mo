#!/usr/bin/perl

package MO::Compile::Role::Conflict;
use Moose;

has name => (
	isa  => "Str",
	is   => "ro",
	lazy => 1,
	default => sub { $_[0]->items->[0]->name }
);

has items => (
	isa => "ArrayRef",
	is  => "ro",
	auto_deref => 1,
	required   => 1,
);

__PACKAGE__;

__END__

