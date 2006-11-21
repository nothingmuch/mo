#!/usr/bin/perl

package Currency;

use strict;
use warnings;

BEGIN { $MO::Run::Aux::MO_NATIVE_RUNTIME = 1 }

use MO::Run::Aux;

use MO::Compile::Class::MI;
use MO::Compile::Attribute::Simple;
use MO::Compile::Method::Simple;

use Role::Eq;
use Role::Ord;
use Role::Printable;

MO::Run::Aux::registry()->register_class(
	MO::Compile::Class::MI->new(
		roles => [ map { MO::Run::Aux::registry()->role_of_package("Role::$_") } qw/Ord Printable/ ],
		attributes => [
			MO::Compile::Attribute::Simple->new(
				name => "symbol",
			),
			MO::Compile::Attribute::Simple->new(
				name => "amount",
			),
		],
		instance_methods => [
			MO::Compile::Method::Simple->new(
				name => "compare",
				definition => sub {
					my ( $self, $other ) = @_;
					die "Can't compare units of a different currency" unless $self->symbol eq $other->symbol;
					$self->amount <=> $other->amount;
				},
			),
			MO::Compile::Method::Simple->new(
				name => "to_string",
				definition => sub {
					my ( $self, $other ) = @_;
					sprintf("%s%.02f", $self->symbol, $self->amount);
				},
			),
		],
	)
);

####

MO::Run::Aux::registry()->emit_all_classes();

MO::Run::Aux::compile_pmc();

1;

