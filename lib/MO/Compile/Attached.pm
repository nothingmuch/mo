#!/usr/bin/perl

package MO::Compile::Attached;
use Moose::Role;

requires "attached_item";

requires "origin";

use tt;
[% FOR method IN [ "is_composition_failure", "is_weak", "stringify" ] %]

sub [% method %] {
	my ( $self, @args ) = @_;
	$self->attached_item->can("[% method %]") && $self->attached_item->[% method %](@args);
}

[% END %]
no tt;

__PACKAGE__;

__END__

