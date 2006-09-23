#!/usr/bin/perl

package MO::Compile::Composable::Symmetric::Util::Merge;
use Moose;

extends "MO::Util::Collection::Merge";

use MO::Compile::Composable::Symmetric::Conflict;

has conflict_class => (
	isa => "Str",
	is  => "rw",
	default => "MO::Compile::Composable::Symmetric::Conflict",
);

sub merge_conflict {
	my ( $self, @items ) = @_;

	$self->conflict_class->new(
		items => \@items,
	);
}

__PACKAGE__;

__END__
