#!/usr/bin/perl

package MO::Compile::Attribute::Compiled;
use Moose::Role;

use MO::Compile::Attribute::Compiled::Attached;

requires "name";

requires "methods";

requires "slots";

sub attach {
	my ( $self, $origin ) = @_;

	MO::Compile::Attribute::Compiled::Attached->new(
		origin    => $origin,
		attribute => $self,
	);
}

__PACKAGE__;

__END__
