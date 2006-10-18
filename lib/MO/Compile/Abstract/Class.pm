#!/usr/bin/perl

package MO::Compile::Abstract::Class;
use Moose::Role;

requires "superclasses";

requires "class_precedence_list";

requires "all_class_methods";

requires "all_instance_methods";

sub _instance_interface {
	my ( $self, @args ) = @_;
	$self->_interface_from_methods( $self->all_instance_methods(@args) );
}

sub _class_interface {
	my ( $self, @args ) = @_;
	$self->_interface_from_methods( $self->all_class_methods(@args) );
}

sub _interface_from_methods {
	my ( $self, @methods ) = @_;

	MO::Run::ResponderInterface::MethodTable->new(
		methods => { map { $_->name => $self->compile_method($_) } @methods },
	);
}

sub compile_method {
	my ( $self, $attached_method ) = @_;

	warn Carp::longmess unless $attached_method->can("attached_item");

	my $method = $attached_method->attached_item;
	my $origin = $attached_method->origin;

	return $method->compile(
		target => $self,
		origin => $origin,
	);
}

__PACKAGE__;

__END__
