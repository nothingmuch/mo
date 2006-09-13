#!/usr/bin/perl

package MO::Compile::AttributeGrammar::Attribute::Bestowed;
use Moose;

has method => (
	does => "MO::Compile::Method",
	is   => "ro",
	required => 1,
	handles => [qw/name/],
);

sub compile {
	my $self = shift;
	$self->method->definition;
}

__PACKAGE__;

__END__
