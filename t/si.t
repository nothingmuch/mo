#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'MO::Compile::Class::SI';
use ok 'MO::Run::Method::Simple';
use ok 'MO::Run::Invocation::Method';
use ok 'MO::Run::Responder::Object';

my $base = MO::Compile::Class::SI->new(
	regular_instance_methods => {
		foo => MO::Run::Method::Simple->new( body => sub { "foo" } ),
	},
);

my $sub = MO::Compile::Class::SI->new(
	superclass               => $base,
	regular_instance_methods => {
		bar => MO::Run::Method::Simple->new( body => sub { "bar" } ),
	},
);

can_ok( $base, "all_instance_methods" );

can_ok( $base, "instance_interface" );

my $obj_box = MO::Run::Responder::Object->new(
	object => bless {}, "foomoooselaaaaaaaaaaaaaaaa",
);

is(
	$base->instance_interface->dispatch(
		$obj_box,
		MO::Run::Invocation::Method->new( name => "foo", arguments => [ ] ),
	)->(),
	"foo",
	"base->foo",
);

is(
	$base->instance_interface->dispatch(
		$obj_box,
		MO::Run::Invocation::Method->new( name => "bar", arguments => [ ] ),
	),
	undef,
	"base->bar",
);

is(
	$sub->instance_interface->dispatch(
		$obj_box,
		MO::Run::Invocation::Method->new( name => "foo", arguments => [ ] ),
	)->(),
	"foo",
	"sub->foo",
);

is(
	$sub->instance_interface->dispatch(
		$obj_box,
		MO::Run::Invocation::Method->new( name => "bar", arguments => [ ] ),
	)->(),
	"bar",
	"sub->bar",
);
