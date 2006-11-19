#!/usr/bin/perl

package MO::Compile::Attribute::Attached;
use Moose;

with qw/
	MO::Compile::Attribute
	MO::Compile::Attached
/;

sub origin {}
has origin => (
	isa => "Object",
	is  => "ro",
	required => 1,
);

BEGIN {

has attribute => (
	does => "MO::Compile::Attribute",
	is   => "ro",
	required => 1,
	handles  => [qw/name/],
);

}

sub fields {
	my ( $self, $class ) = @_;

	$self->attribute->fields(
		target => $class,
		origin => $self->origin,
	);
}

sub attached_item {
	my $self = shift;
	$self->attribute;
}

__PACKAGE__;

__END__
