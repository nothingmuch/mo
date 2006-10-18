#!/usr/bin/perl

package MO::Util::Collection::Shadow;
use Moose;

sub shadow {
	my ( $self, $head, @tail ) = @_;

	return () unless $head;

	my $head_collection = $self->collection( $head );

	unless ( @tail ) {
		return $head_collection->items;
	} else {
		my @tail_items = $self->shadow( @tail );
		my @remaining = grep { !$head_collection->includes( $_->name ) } @tail_items;
		return ( @remaining, $head_collection->items );
	}
}

sub collection {
	my ( $self, $item ) = @_;
	$item;
}

__PACKAGE__;

__END__
