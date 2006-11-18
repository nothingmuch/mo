#!/usr/bin/perl

package Point;

use strict;
use warnings;

BEGIN { $MO::Run::Aux::MO_NATIVE_RUNTIME = 1 }

use MO::Run::Aux;

use MO::Compile::Class::MI;
use MO::Compile::Attribute::Simple;
use MO::Compile::Method::Simple;

MO::Run::Aux::registry()->register_class(
	MO::Compile::Class::MI->new(
		attributes => [
			MO::Compile::Attribute::Simple->new(
				name => "x",
			),
			MO::Compile::Attribute::Simple->new(
				name => "y",
			),
		],
		instance_methods => [
			MO::Compile::Method::Simple->new(
				name => "distance",
				definition => sub {
					my ( $self, $other ) = @_;
					sqrt( ( abs( $self->x - $other->x ) ** 2 ) + ( abs( $self->y - $other->y ) ** 2 ) );
				},
			),
		],
	)
);

####

MO::Run::Aux::registry()->emit_all_classes();

MO::Run::Aux::compile_pmc();

1;

