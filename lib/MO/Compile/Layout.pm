#!/usr/bin/perl

package MO::Compile::Layout;
use Moose::Role;

requires "create_instance_structure";

requires "fields";

requires "slot_for_field";

sub slots {
	my $self = shift;
	$self->slots_for_fields( $self->fields );
}

sub slots_for_fields {
	my ( $self, @fields ) = @_;
	map { $self->slot_for_field($_) } @fields;
}

__PACKAGE__;

__END__
