#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok "MO::Util::Collection";
use ok "MO::Util::Collection::Shadow";
use ok "MO::Util::Collection::Merge";
use ok "MO::Compile::Method::Simple";

my $moose = MO::Compile::Method::Simple->new(
	name       => "moose",
	definition => sub { },
);

my $elk = MO::Compile::Method::Simple->new(
	name       => "elk",
	definition => sub { },
);

my $elk2 = MO::Compile::Method::Simple->new(
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

my $c2 = MO::Util::Collection->new( $moose, $elk2 );

is_deeply(
	[ sort MO::Util::Collection::Shadow->new->shadow( $c, $c2 ) ],
	[ sort $moose, $elk ],
	"shadowing over same named items",
);

eval { MO::Util::Collection::Merge->new->merge( $c, $c2 ) };

ok( $@, "merging with conflicting names throws error" );
like( $@, qr/merged.*name/, "the right error" );

my $c3 = MO::Util::Collection->new( $moose, $elk );

is_deeply(
	[ eval { sort MO::Util::Collection::Merge->new->merge( $c, $c3 ) } ],
	[ sort $moose, $elk ],
	"same values, same name is not a conflict",
);

eval { MO::Util::Collection->new( $elk, $elk2 ) };

ok( $@, "can't create collection with two items of the same name" );
like( $@, qr/name conflict/, "the right error" );

