#!/usr/bin/perl

package MO::Util::Collection::Shadow::Accessor;
use Moose;
extends 'MO::Util::Collection::Shadow';

has accessor => (
	isa => "Str|CodeRef",
	is  => "rw",
	required => 1,
);

sub collection {
	my ( $self, $item ) = @_;
	my $accessor = $self->accessor;
	$item->$accessor;
}

__PACKAGE__;

__END__
