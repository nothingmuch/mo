#!/usr/bin/perl

package MO::Compile::Class::Layout::Hash;
use Moose;

use MO::Compile::Slot::HashElement;

has class => (
	does => "MO::Compile::Class",
	is   => "ro",
	required => 1,
);

has fields => (
	isa => "ArrayRef",
	is  => "ro",
	auto_deref => 1,
	required   => 1,
);

sub BUILD {
	my $self = shift;
	foreach my $field ( $self->fields ) {
		if ( $field->name =~ /:/ ) {
			warn "The field name " . $field->name . " may conflict with private attribute namespacing";
		}
	}
}

sub slots {
	my $self = shift;
	$self->slots_for_fields( $self->fields );
}

sub slots_for_fields {
	my ( $self, @fields ) = @_;
	map { $self->slot_for_field($_) } @fields;
}

sub slot_for_field {
	my ( $self, $field ) = @_;

	$self->slot_class($field)->new(
		name => $self->slot_name_for_field($field),
	);
}

sub slot_name_for_field {
	my ( $self, $field ) = @_;

	$field->private
		? sprintf('private:%s::%s', $field->origin, $field->name)
		: $field->name;
}

sub slot_class {
	my ( $self, $field ) = @_;
	"MO::Compile::Slot::HashElement";
}

sub empty_instance_structure {
	my $self = shift;
	return {};
}

sub create_instance_structure {
	my ( $self ) = @_;
	my $instance = $self->empty_instance_structure;
	$_->construct( $instance ) for $self->slots;
	return $instance;
}

__PACKAGE__;

__END__
