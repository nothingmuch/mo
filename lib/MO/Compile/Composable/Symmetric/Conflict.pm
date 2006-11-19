#!/usr/bin/perl

package MO::Compile::Composable::Symmetric::Conflict;
use Moose;

with "MO::Compile::CompositionFailure";

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

sub stringify {
	my $self = shift;

	return "Symmetric composition error over key '" . $self->name . "' between "
		. join(", ", $self->stringify_items);
}

sub stringify_items {
	my $self = shift;

	map { $self->stringify_item($_) } $self->items;
}

sub stringify_item {
	my ( $self, $item ) = @_;

	if ( $item->does("MO::Compile::Attached") ) {
		return $item->attached_item . " (from " . $item->origin . ")";
	} else {
		return $item;
	}
}

__PACKAGE__;

__END__

