#!/usr/bin/perl

package MO::Util::Collection::Merge;
use Moose;

use Carp qw/croak/;
use Scalar::Util qw/refaddr/;

sub merge {
	my ( $self, @collections ) = @_;

	my %seen;

	my @items = grep { !$seen{ $self->_item_uuid($_) }++ } map { $_->items } @collections;

	%seen = ();

	my @names = grep { !$seen{$_}++ } map { $_->name } @items;

	if ( @names == @items ) {
		return @items;
	} else {
		my %by_name;
		push @{ $by_name{$_->name} ||= [] }, $_ for @items;

		foreach my $items ( values %by_name ) {
			if ( @$items > 1 ) {
				$items = $self->merge_conflict( @$items );
			} else {
				$items = $items->[0];
			}
		}

		return @by_name{@names};
	}
}

sub _item_uuid {
	my ( $self, $item ) = @_;
	$item = $item->attached_item while $item->does("MO::Compile::Attached");
	refaddr($item);
}

sub merge_conflict {
	my ( $self, @items ) = @_; # with the same name
	croak "@items cannot be merged as they share a name";
}

__PACKAGE__;

__END__
