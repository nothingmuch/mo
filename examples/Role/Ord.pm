#!/usr/bin/perl

package Role::Ord;

use strict;
use warnings;

BEGIN { $MO::Run::Aux::MO_NATIVE_RUNTIME = 1 }

use MO::Run::Aux;

use MO::Compile::Role;
use MO::Compile::Method::Simple;
use MO::Compile::Method::Stub;

MO::Run::Aux::registry()->register_role(
	MO::Compile::Role->new(
		roles => [ MO::Run::Aux::registry()->role_of_package("Role::Eq") ],
		instance_methods => [
			MO::Compile::Method::Stub->new( name => "compare" ),
			MO::Compile::Method::Simple->new(
				name => "equal_to",
				definition => sub {
					my ( $self, $other ) = @_;
					$self->compare( $other ) == 0;
				}
			),
			MO::Compile::Method::Simple->new(
				name => "greater_than",
				definition => sub {
					my ( $self, $other ) = @_;
					$self->compare( $other ) == 1;
				}
			),
			MO::Compile::Method::Simple->new(
				name => "less_than",
				definition => sub {
					my ( $self, $other ) = @_;
					$self->compare( $other ) == -1;
				}
			),
			MO::Compile::Method::Simple->new(
				name => "less_than_or_equal_to",
				definition => sub {
					my ( $self, $other ) = @_;
					not $self->greater_than( $other );
				}
			),
			MO::Compile::Method::Simple->new(
				name => "greater_than_or_equal_to",
				definition => sub {
					my ( $self, $other ) = @_;
					not $self->less_than( $other );
				}
			),
		],
	),
);

1;
