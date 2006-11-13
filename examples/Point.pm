#!/usr/bin/perl

package Point;

use strict;
use warnings;

use MO::Run::Aux;

BEGIN { $MO::Run::Aux::MO_NATIVE_RUNTIME = 1 }

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

use Generate::PMC::File;
use Data::Dump::Streamer ();

no strict 'refs';

Generate::PMC::File->new(
	input_file              => __FILE__,
	include_freshness_check => 0,
	body                    => [
		<<'PRELUDE',
# registry blah etc, "macros" used inside generated routines
use MO::Run::Aux;

# make the "macros" work with native perl OO semantics
BEGIN { $MO::Run::Aux::MO_NATIVE_RUNTIME = 1 }

# needed for constructor, accessors
# these can go away with codegen
use MO::Compile::Class::Layout::Hash;
use MO::Compile::Field::Simple;
use MO::Compile::Attribute::Simple; # initializers

PRELUDE
		Data::Dump::Streamer::Dump(*{"::" . __PACKAGE__ . "::"})->Out
	],
)->write_pmc();

