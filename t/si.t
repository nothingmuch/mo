#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'MO::Compile::Class::SI';
use ok 'MO::Compile::Method::Simple';
use ok 'MO::Compile::Attribute::Simple';
use ok 'MO::Run::Invocation::Method';
use ok 'MO::Run::Responder::Object';

my $base = MO::Compile::Class::SI->new(
	regular_instance_methods => MO::Util::Collection->new(
		MO::Compile::Method::Simple->new(
			name       => "foo",
			definition => sub { "foo" },
		),
	),
	attributes => MO::Util::Collection->new(
		MO::Compile::Attribute::Simple->new(
			name => "elk",
		),
	),
);

my $sub = MO::Compile::Class::SI->new(
	superclass               => $base,
	regular_instance_methods => MO::Util::Collection->new(
		MO::Compile::Method::Simple->new(
			name       => "bar",
			definition => sub { "bar" },
		),
	),
);

my $base_box = MO::Run::Responder::Object->new(
	object              => $base, # meh ;-)
	responder_interface => $base->class_interface,
);

my $base_obj_box = $base_box->responder_interface->dispatch(
	$base_box,
	MO::Run::Invocation::Method->new( name => "create_instance", arguments => [ elk => "moose" ] ),
)->();

my $sub_box = MO::Run::Responder::Object->new(
	object              => $sub, # meh ;-)
	responder_interface => $sub->class_interface,
);

my $sub_obj_box = $sub_box->responder_interface->dispatch(
	$sub_box,
	MO::Run::Invocation::Method->new( name => "create_instance", arguments => [ elk => "moose" ] ),
)->();

is(
	$base->instance_interface->dispatch(
		$base_obj_box,
		MO::Run::Invocation::Method->new( name => "foo", arguments => [ ] ),
	)->(),
	"foo",
	"base->foo",
);

is(
	$base->instance_interface->dispatch(
		$base_obj_box,
		MO::Run::Invocation::Method->new( name => "bar", arguments => [ ] ),
	),
	undef,
	"base->bar",
);

is(
	$base->instance_interface->dispatch(
		$base_obj_box,
		MO::Run::Invocation::Method->new( name => "elk", arguments => [ ] ),
	)->(),
	"moose",
	"base->elk",
);

is(
	$base->instance_interface->dispatch(
		$base_obj_box,
		MO::Run::Invocation::Method->new( name => "elk", arguments => [ "val" ] ),
	)->(),
	"val",
	"base->elk('val')",
);

is(
	$base->instance_interface->dispatch(
		$base_obj_box,
		MO::Run::Invocation::Method->new( name => "elk", arguments => [ ] ),
	)->(),
	"val",
	"base->elk",
);

is(
	$sub->instance_interface->dispatch(
		$sub_obj_box,
		MO::Run::Invocation::Method->new( name => "foo", arguments => [ ] ),
	)->(),
	"foo",
	"sub->foo",
);

is(
	$sub->instance_interface->dispatch(
		$sub_obj_box,
		MO::Run::Invocation::Method->new( name => "bar", arguments => [ ] ),
	)->(),
	"bar",
	"sub->bar",
);


