#!/usr/bin/perl

package MO::Compile::Class::SI;
use Moose;

use MO::Run::ResponderInterface::MethodTable;

has superclass => (
	isa => "MO::Compile::Class::SI",
	is  => "ro",
);

has attributes => ( # FIXME unused
	isa => "HashRef",
	is  => "ro",
);

has regular_instance_methods => (
	isa => "HashRef",
	is  => "ro",
);

has class_methods => (
	isa => "HashRef",
	is  => "ro",
);

sub instance_methods {
	my $self = shift;
	$self->regular_instance_methods; # FIXME project over interfaced class
}

sub class_precedence_list {
	my $self = shift;
	
	if ( my $superclass = $self->superclass ) {
		return ( $self, $superclass->class_precedence_list );
	} else {
		return $self;
	}
}

sub _get_all {
	my ( $self, $accessor, @args ) = @_;
	my %map = map { %{ $_->$accessor(@args) } } reverse $self->class_precedence_list;
	return \%map;
}

sub all_class_methods {
	my $self = shift;
	$self->_get_all( "class_methods" );	
}

sub all_instance_methods {
	my $self = shift;
	$self->_get_all( "instance_methods" );	
}

sub all_accessors {
	my $self = shift;
	$self->_get_all( "attributes" );
}

sub class_interface {
	my $self = shift;

	MO::Run::ResponderInterface::MethodTable->new(
		methods => $self->all_class_methods,
	);
}

sub instance_interface {
	my $self = shift;

	MO::Run::ResponderInterface::MethodTable->new(
		methods => $self->all_instance_methods,
	);
}

__PACKAGE__;

__END__
