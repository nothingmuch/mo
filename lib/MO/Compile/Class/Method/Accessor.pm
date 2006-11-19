#!/usr/bin/perl

package MO::Compile::Class::Method::Accessor;
use Moose;

with "MO::Compile::Method";

use MO::Compile::Method::Compiled;
use MO::Run::Aux;

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

has compiled_attribute => (
	does => "MO::Compile::Attribute::Compiled",
	is   => "ro",
	required => 1,
);

sub attribute {
	my $self = shift;
	$self->compiled_attribute->attribute;
}

sub compile {
	my ( $self, %params ) = @_;

	my $slot = $self->slot;

	return MO::Compile::Method::Simple::Compiled->new(
		method => $self,
		body   => sub {
			my ( $instance, @args ) = @_;

			my $structure = MO::Run::Aux::unbox_value($instance);

			if ( @args ) {
				return $slot->set_value( $structure, @args );
			} else {
				return $slot->get_value( $structure );
			}
		},
	);
}

__PACKAGE__;

__END__

