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
	map { $self->slot_class($_)->new( name => $_->name ) } $self->fields;
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
