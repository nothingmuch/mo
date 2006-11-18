#!/usr/bin/perl

package Point3D;

use strict;
use warnings;

BEGIN { $MO::Run::Aux::MO_NATIVE_RUNTIME = 1 }

use MO::Run::Aux;

use MO::Compile::Class::MI;
use MO::Compile::Attribute::Simple;
use MO::Compile::Method::Simple;

use Point ();

MO::Run::Aux::registry()->register_class(
	MO::Compile::Class::MI->new(
		superclasses => [ MO::Run::Aux::registry()->class_of_package("Point") ],
		attributes => [
			MO::Compile::Attribute::Simple->new(
				name => "z",
			),
		],
		instance_methods => [
			MO::Compile::Method::Simple->new(
				name => "distance",
				definition => sub {
					my ( $self, $other ) = @_;

					my $two_dim_distance = $self->SUPER::distance( $other );

					sqrt( ( $two_dim_distance ** 2 ) + ( abs( $self->z - $other->z ) ** 2 ) );
				},
			),
		],
	)
);

####

MO::Run::Aux::registry()->emit_all_classes();

MO::Run::Aux::compile_pmc();

1;

