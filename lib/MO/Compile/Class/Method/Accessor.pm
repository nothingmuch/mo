#!/usr/bin/perl

package MO::Compile::Class::Method::Accessor;
use Moose;

with "MO::Compile::Method";

use MO::Compile::Method::Compiled;

sub name {}
has name => (
	isa => "Str",
	is  => "ro",
	required => 1,
);

has slot => (
	does => "MO::Compile::Slot",
	is   => "ro",
	required => 1,
);

has attribute => (
	does => "MO::Compile::Attribute::Compiled",
	is   => "ro",
	required => 1,
);

sub compile {
	my ( $self, %params ) = @_;

	my $slot = $self->slot;

	return MO::Compile::Method::Simple::Compiled->new(
		body => sub	{
			my ( $instance, @args ) = @_;

			if ( @args ) {
				return $slot->set_value( $instance->invocant, @args ); # FIXME unbox macro
			} else {
				return $slot->get_value( $instance->invocant );
			}
		},
	);
}

__PACKAGE__;

__END__

