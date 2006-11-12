#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use ok "MO::Run::Aux::Stack";

my $stack = MO::Run::Aux::Stack->new;

isa_ok( $stack, "MO::Run::Aux::Stack" );

can_ok( $stack, "push" );

my $frame1 = $stack->push("a");

isa_ok( $frame1, "MO::Run::Aux::Stack::Frame" );

my $frame2 = $stack->push("b");

is_deeply(
	[ $stack->items ],
	[ qw/a b/ ],
	"stack items",
);

dies_ok { $frame1->pop } "can only pop last frame";

is_deeply(
	[ $stack->items ],
	[ qw/a b/ ],
	"stack items",
);

lives_ok { $frame2->pop } "can pop tail";

is_deeply(
	[ $stack->items ],
	[ qw/a/ ],
	"stack items",
);

$stack->pop( $frame1 );

is_deeply(
	[ $stack->items ],
	[ ],
	"stack is empty",
);

$stack->clear;

$stack->push("moose");

is_deeply(
	[ $stack->items ],
	[ qw/moose/ ],
	"moose on the stack",
);

is( $stack->get_item(0), "moose", "indeed!" );

$stack->clear;

is_deeply(
	[ $stack->items ],
	[ ],
	"stack is empty",
);

{
	my $f = $stack->push("item");

	is_deeply(
		[ $stack->items ],
		[ qw/item/ ],
		"stack items after push",
	);

	{
		my $f = $stack->push("item2");

		is_deeply(
			[ $stack->items ],
			[ qw/item item2/ ],
			"stack items after second push",
		);
	}		

	is_deeply(
		[ $stack->items ],
		[ qw/item/ ],
		"stack items - autopop",
	);
}

is_deeply(
	[ $stack->items ],
	[ ],
	"stack items - autopop",
);
