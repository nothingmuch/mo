#!/usr/bin/perl

package Role::Printable;

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
			MO::Compile::Method::Stub->new( name => "to_string" ),
			MO::Compile::Method::Simple->new(
				name => "say",
				definition => sub {
					my $self = shift;
					local $\ = "\n";
					print $self->to_string;
				},
			),
		],
	),
);

1;

