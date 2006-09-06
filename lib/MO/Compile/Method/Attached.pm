#!/usr/bin/perl

package MO::Compile::Method::Attached;
use Moose;

with qw/
	MO::Compile::Method
	MO::Compile::Attached
/;

BEGIN {

has origin => (
	isa => "Object",
	is  => "ro",
	required => 1,
);

has method => (
	does => "MO::Compile::Method",
	is   => "ro",
	required => 1,
	handles => [qw/name definition/],
);

}

sub attached_item {
	my $self = shift;
	$self->method;
}

__PACKAGE__;

__END__
