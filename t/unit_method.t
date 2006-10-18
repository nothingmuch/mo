#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok "MO::Compile::Method::Simple";
use ok "MO::Compile::Method::Simple::Compiled";

my $def = MO::Compile::Method::Simple::Compiled->new(
	body => sub { "magic" },
);

ok( $def->body, "body set" );
is( $def->body->(), "magic", "invoked" );

my $method = MO::Compile::Method::Simple->new(
	name       => "moose",
	definition => $def,
);

is( $method->definition, $def, "definition set" );


my $method2 = MO::Compile::Method::Simple->new(
	name       => "elk",
	definition => sub { 42 },
);

isa_ok( $method2->definition, "MO::Compile::Method::Simple::Compiled" );
is( $method2->definition->body->(), 42, "coerced body" );

