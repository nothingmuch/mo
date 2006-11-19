#!/usr/bin/perl

package MO::Compile::Abstract::Class;
use Moose::Role;

use MO::Util;

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
		methods => { map { $_->name => $self->compile_method($_) } $self->filter_composition_failures( @methods ) },
		origin  => $self,
	);
}

sub filter_composition_failures {
	my ( $self, @objects ) = @_;

	my ( $ok, $failures ) = MO::Util::part_composition_failures(@objects);

	$self->handle_composition_failures( @$failures ) if @$failures;

	return @$ok;
}

sub handle_composition_failures {
	my ( $self, @failures ) = @_;

	# FIXME make into an error object so that it can be dissected, this is potentially a huge $@
	die join("\n  ",
		"Composition failures in $self:",
		map { $_->can("stringify") ? $_->stringify : $_ } @failures
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
