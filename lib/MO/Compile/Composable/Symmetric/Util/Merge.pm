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

sub filter_non_weak_items {
	my ( $self, @items ) = @_;

	grep { not( $_->can("is_weak") && $_->is_weak ) } @items;
}

sub merge_conflict {
	my ( $self, @items ) = @_;

	my @non_weak = $self->filter_non_weak_items( @items );

	if ( @non_weak == 1 ) {
		return $non_weak[0];
	} else {
		$self->conflict_class->new(
			items => \@items,
		);
	}
}

__PACKAGE__;

__END__
