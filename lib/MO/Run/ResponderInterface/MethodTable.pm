#!/usr/bin/perl

package MO::Run::ResponderInterface::MethodTable;
use Moose;

with "MO::Run::Abstract::ResponderInterface";

has methods => (
	isa => "HashRef",
	is  => "ro",
);

sub method {
	my ( $self, $name ) = @_;
	$self->methods->{$name};
}

sub dispatch {
	my ( $self, $responder, $inv ) = @_;
	
	if ( my $def = $self->method( $inv->name ) ) {
		my @args = ( $responder->object, $inv->arguments );
		my $body = $def->body;
		return sub { $body->( @args ) }; # goto?
	}

	return;
}

__PACKAGE__;

__END__
