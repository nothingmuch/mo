#!/usr/bin/perl

package MO::Compile::Attribute;
use Moose::Role;

use MO::Compile::Attribute::Attached;

requires "name";

requires "fields";

requires "compile";

sub attach {
	my ( $self, $origin ) = @_;

	MO::Compile::Attribute::Attached->new(
		attribute => $self,
		origin => $origin,
	);
}

__PACKAGE__;

__END__
