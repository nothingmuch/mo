#!/usr/bin/perl

package Role::Eq;

use strict;
use warnings;

BEGIN { $MO::Run::Aux::MO_NATIVE_RUNTIME = 1 }

use MO::Run::Aux;

use MO::Compile::Role;
use MO::Compile::Method::Simple;
use MO::Compile::Method::Stub;

MO::Run::Aux::registry()->register_role(
	MO::Compile::Role->new(
		instance_methods => [
			MO::Compile::Method::Stub->new( name => "equal_to" ),
			MO::Compile::Method::Simple->new(
				name => "not_equal_to",
				definition => sub {
					my ( $self, $other ) = @_;
					not $self->equal_to( $other );
				}
			),
		],
	),
);

1;
