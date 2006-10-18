#!/usr/bin/perl

package MO::Run::ResponderInterface::Filtered;
use Moose;

with "MO::Run::Abstract::ResponderInterface";

has responder_interface => (
	does => "MO::Run::Abstract::ResponderInterface",
	is   => "rw",
	required => 1,
);

has responder_filter => (
	isa => "CodeRef",
	is  => "rw",
);

has invocation_filter => (
	isa => "CodeRef",
	is  => "rw",
);

has around_filter => (
	isa => "CodeRef",
	is  => "rw",
);

sub dispatch {
	my ( $self, $responder, $invocation ) = @_;

	$responder  = $self->process_responder($responder, $invocation);
	$invocation = $self->process_invocation($invocation, $responder);

	if ( my $thunk = $self->responder_interface->dispatch( $responder, $invocation ) ) {
		return $self->process_dispatch_thunk(
			$thunk,
			$responder,
			$invocation,
		);
	} else {
		return;
	}
}

sub process_responder {
	my ( $self, $responder, $invocation ) = @_;

	if ( my $filter = $self->responder_filter ) {
		return $filter->( $responder, $invocation, $self->responder_interface );
	} else {
		return $responder;
	}
}

sub process_invocation {
	my ( $self, $invocation, $responder ) = @_;

	if ( my $filter = $self->invocation_filter ) {
		return $filter->( $invocation, $responder, $self->responder_interface );
	} else {
		return $invocation;
	}
}

sub process_dispatch_thunk {
	my ( $self, $thunk, $responder, $invocation ) = @_;

	if ( my $around = $self->around_filter ) {
		return $around->($thunk, $responder, $invocation, $self->responder_interface);
	} else {
		return $thunk;
	}
}

__PACKAGE__;

__END__
