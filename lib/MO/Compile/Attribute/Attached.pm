#!/usr/bin/perl

package MO::Compile::Attribute::Attached;
use Moose;

with qw/
	MO::Compile::Attribute
	MO::Compile::Attached
/;

BEGIN {

has origin => (
	isa => "Object",
	is  => "ro",
	required => 1,
);

has attribute => (
	does => "MO::Compile::Attribute",
	is   => "ro",
	required => 1,
	handles  => [qw/name fields compile/],
);

}

sub attached_item {
	my $self = shift;
	$self->attribute;
}

__PACKAGE__;

__END__
