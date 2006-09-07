#!/usr/bin/perl

package MO::Compile::Attribute::Compiled::Attached;
use Moose;

with qw/
	MO::Compile::Attribute::Compiled
	MO::Compile::Attached
/;

BEGIN {

has origin => (
	isa => "Object",
	is  => "ro",
	required => 1,
);

has attribute => (
	does => "MO::Compile::Attribute::Compiled",
	is   => "ro",
	required => 1,
	handles  => [qw/name initialize/],
);

}

use tt;
[% FOREACH delegation IN ["methods","private_methods"] %]
sub [% delegation %] {
	my ( $self, @args ) = @_;
	map { $_->attach( $self->origin ) } $self->attribute->[% delegation %]( @args )
}
[% END %]
no tt;

sub attached_item {
	my $self = shift;
	$self->attribute;
}	

__PACKAGE__;

__END__

=pod

=head1 NAME

MO::Compile::Attribute::Compiled::Attached - 

=head1 SYNOPSIS

	use MO::Compile::Attribute::Compiled::Attached;

=head1 DESCRIPTION

=cut


