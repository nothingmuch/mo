#!/usr/bin/perl

package MO::Compile::Attached;
use Moose::Role;

requires "attached_item";

requires "origin";

sub is_composition_failure {
	my $self = shift;

	$self->attached_item->can("is_composition_failure") && $self->attached_item->is_composition_failure;
}

__PACKAGE__;

__END__

