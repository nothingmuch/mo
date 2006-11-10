#!/usr/bin/perl

package MO::Run::ResponderInterface::MethodTable;
use Moose;

with "MO::Run::Abstract::ResponderInterface";

has origin => (
	does => "MO::Compile::Origin",
	is   => "ro",
);

has methods => (
	isa => "HashRef",
	is  => "rw",
	required => 1,
);

sub stack_frame {
	my ( $self, %params ) = @_;
	$params{stack_frame} || $self->origin;
}

sub method {
	my ( $self, $inv ) = @_;
	$self->methods->{$inv->name};
}

sub dispatch {
	my ( $self, $responder, $inv, %params ) = @_;

	if ( my $def = $self->method( $inv ) ) {
		my @args = ( $responder, $inv->arguments );
		my $body = $def->body;

		if ( my $stack = $params{stack} ) { # FIXME not yet in use
			my $caller = $self->stack_frame(%params) || die "don't have value for caller";
			return sub { my $frame = $stack->push( $caller ); $body->( @args ) };
		} else {
			return sub { $body->( @args ) };
		}
	}

	return;
}

__PACKAGE__;

__END__
