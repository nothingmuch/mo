#!/usr/bin/perl

package MO::Compile::Composable::Symmetric::Util::Merge;
use Moose;

extends "MO::Util::Collection::Merge";

use MO::Compile::Role::Conflict;

has conflict_class => (
	isa => "Str",
	is  => "rw",
	default => "MO::Compile::Role::Conflict",
);

sub merge_conflict {
	my ( $self, @items ) = @_;

	$self->conflict_class->new(
		items => \@items,
	);
}

__PACKAGE__;

__END__
