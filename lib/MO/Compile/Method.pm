#!/usr/bin/perl

package MO::Compile::Method;
use Moose::Role;

use MO::Compile::Method::Attached;

requires "name";

requires "definition";

sub attach {
	my ( $self, $origin ) = @_;

	MO::Compile::Method::Attached->new(
		origin => $origin,
		method => $self,
	);
}

__PACKAGE__;

__END__

