#!/usr/bin/perl

package MO::Compile::Method::Private;
use Moose;

with qw/MO::Compile::Method/;

BEGIN {

has method => (
	does => "MO::Compile::Method",
	is   => "ro",
	required => 1,
	handles => [qw/name compile/],
);

has visible_from => (
	does => "ArrayRef", # FIXME collection?
	is   => "ro",
	required => 1,
);

}

__PACKAGE__;

__END__
