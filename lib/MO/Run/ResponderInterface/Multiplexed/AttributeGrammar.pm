#!/usr/bin/perl

package MO::Run::ResponderInterface::Multiplexed::AttributeGrammar;
use Moose;

with "MO::Run::ResponderInterface::Multiplexed";

use Carp qw/croak/;

has child => (
	isa => "HashRef",
	is  => "rw",
	required => 1,
);

has root => (
	isa => "HashRef",
	is  => "rw",
	required => 1,
);

has parent => (
	isa => "HashRef",
	is  => "rw",
	required => 1,
);

sub fallback_interface {}
has fallback_interface => (
	does => "MO::Run::Abstract::ResponderInterface",
	is   => "rw",
	required => 1,
);

sub interface_for {
	my ( $self, $responder, $inv, %params ) = @_;

	my $stack = $params{stack} || croak "Can't do per-caller multiplexing without a stack";

	if ( my $caller = $stack->tail ) {
		my $ag;

		if ( $caller->isa("MO::Compile::AttributeGrammar::Instance") ) {
			$ag = $caller->attribute_grammar;
		} elsif ( $caller->isa("MO::Compile::AttributeGrammar") ) {
			$ag = $caller;
		}

		if ( $ag ) {
			if ( $responder->invocant == $MO::Compile::AttributeGrammar::AG_ROOT->invocant ) {
				return $self->interface_for_ag_root($ag);
			} else {
				return $self->interface_for_ag_child($ag);
			}
		}
	}

	return;
}

sub interface_for_ag_child {
	my ( $self, $ag ) = @_;
	$self->child->{$ag};
}

sub interface_for_ag_parent {
	my ( $self, $ag ) = @_;
	$self->parent->{$ag};
}

sub interface_for_ag_root {
	my ( $self, $ag ) = @_;
	$self->root->{$ag};
}

__PACKAGE__;

__END__
