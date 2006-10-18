#!/usr/bin/perl

package MO::Run::ResponderInterface::MethodTable;
use Moose;

with "MO::Run::Abstract::ResponderInterface";

has methods => (
	isa => "HashRef",
	is  => "rw",
	required => 1,
);

sub method {
	my ( $self, $inv ) = @_;
	$self->methods->{$inv->name};
}

sub dispatch {
	my ( $self, $responder, $inv ) = @_;

	if ( my $def = $self->method( $inv ) ) {
		my @args = ( $responder, $inv->arguments );
		my $body = $def->body;
		return sub { $body->( @args ) }; # goto?
	}

	return;
}

__PACKAGE__;

__END__
