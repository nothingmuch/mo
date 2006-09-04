#!/usr/bin/perl

package MO::Compile::Abstract::Class;
use Moose::Role;

requires "superclasses";

requires "class_precedence_list";

requires "all_class_methods";

requires "all_instance_methods";

sub instance_interface {
	my ( $self, @args ) = @_;

	MO::Run::ResponderInterface::MethodTable->new(
		methods => { map { $_->name => $_->definition } $self->all_instance_methods(@args) },
	);
}

sub class_interface {
	my ( $self, @args ) = @_;

	MO::Run::ResponderInterface::MethodTable->new(
		methods => { map { $_->name => $_->definition } $self->all_class_methods(@args) },
	);
}

__PACKAGE__;

__END__
