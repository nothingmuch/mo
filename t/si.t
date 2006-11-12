#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use t::stats;

use ok 'MO::Compile::Class::SI';
use ok 'MO::Compile::Method::Simple';
use ok 'MO::Compile::Attribute::Simple';
use ok 'MO::Run::Aux';

t::stats->start(qw/construct runtime/);

my $base = MO::Compile::Class::SI->new(
	instance_methods => [
		MO::Compile::Method::Simple->new(
			name       => "foo",
			definition => sub { "foo" },
		),
	],
	attributes => [
		MO::Compile::Attribute::Simple->new(
			name => "elk",
		),
	],
);

my $sub = MO::Compile::Class::SI->new(
	superclass               => $base,
	instance_methods => [
		MO::Compile::Method::Simple->new(
			name       => "bar",
			definition => sub { "bar" },
		),
	],
);

t::stats->finish("construct");
t::stats->start("meta_calcs");

my $base_box = MO::Run::Aux::box( $base, $base->class_interface );

my $base_obj_box = MO::Run::Aux::method_call( $base_box, "create_instance", elk => "moose" );

my $sub_box = MO::Run::Aux::box( $sub, $sub->class_interface );

my $sub_obj_box = MO::Run::Aux::method_call( $sub_box, "create_instance", elk => "moose" );

t::stats->finish("meta_calcs");
t::stats->start("dispatch");

is(
	MO::Run::Aux::method_call( $base_obj_box, "foo" ),
	"foo",
	"base->foo",
);

is(
	eval { MO::Run::Aux::method_call( $base_obj_box, "bar" ) },
	undef,
	"base->bar",
);

is(
	MO::Run::Aux::method_call( $base_obj_box, "elk" ),
	"moose",
	"base->elk",
);

is(
	MO::Run::Aux::method_call( $base_obj_box, "elk", "val" ),
	"val",
	"base->elk('val')",
);

is(
	MO::Run::Aux::method_call( $base_obj_box, "elk" ),
	"val",
	"base->elk",
);

is(
	MO::Run::Aux::method_call( $sub_obj_box, "foo" ),
	"foo",
	"sub->foo",
);

is(
	MO::Run::Aux::method_call( $sub_obj_box, "bar" ),
	"bar",
	"sub->bar",
);

t::stats->finish(qw/dispatch runtime/);
