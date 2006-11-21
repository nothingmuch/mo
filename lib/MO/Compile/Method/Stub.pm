#!/usr/bin/perl

package MO::Compile::Method::Stub;
use Moose;

with qw/
	MO::Compile::CompositionFailure
	MO::Compile::Method
	MO::Compile::Weak
/;

sub name {}
has name => (
	isa => "Str",
	is  => "ro",
	required => 1,
);

sub stringify {
	my $self = shift;

	"Required method " . $self->name . " not provided by implementation";
}

sub compile {
	my $self = shift;
	die $self->stringify;
}

__PACKAGE__;

__END__
