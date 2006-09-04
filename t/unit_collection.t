#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok "MO::Util::Collection";
use ok "MO::Compile::Method::Simple";

my $moose = MO::Compile::Method::Simple->new(
	name       => "moose",
	definition => sub { },
);

my $elk = MO::Compile::Method::Simple->new(
	name       => "elk",
	definition => sub { },
);

my $c = MO::Util::Collection->new($moose);

ok( $c->includes($moose), "includes moose" );
ok( !$c->includes($elk), "doesn't include elk" );

ok( eval { $c->add($elk); 1 }, "insert elk" );
ok( $c->includes($elk), "includes elk" );

is_deeply( [ sort $c->items ], [ sort $elk, $moose ], "items" );

ok( $c->remove($moose), "remove moose" );
ok( !$c->includes($moose), "no longer includes moose" );

is_deeply( [ $c->items ], [ $elk ], "items" );
