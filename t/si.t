#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'MO::Compile::Class::SI';
use ok 'MO::Compile::Method::Simple';
use ok 'MO::Compile::Attribute::Simple';
use ok 'MO::Run::Invocation::Method';
use ok 'MO::Run::Responder::Invocant';

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

my $base_box = MO::Run::Responder::Invocant->new(
	invocant            => $base,
	responder_interface => $base->class_interface,
);

my $base_obj_box = $base_box->responder_interface->dispatch(
	$base_box,
	MO::Run::Invocation::Method->new( name => "create_instance", arguments => [ elk => "moose" ] ),
)->();

my $sub_box = MO::Run::Responder::Invocant->new(
	invocant            => $sub,
	responder_interface => $sub->class_interface,
);

my $sub_obj_box = $sub_box->responder_interface->dispatch(
	$sub_box,
	MO::Run::Invocation::Method->new( name => "create_instance", arguments => [ elk => "moose" ] ),
)->();

is(
	$base_obj_box->responder_interface->dispatch(
		$base_obj_box,
		MO::Run::Invocation::Method->new( name => "foo", arguments => [ ] ),
	)->(),
	"foo",
	"base->foo",
);

is(
	$base_obj_box->responder_interface->dispatch(
		$base_obj_box,
		MO::Run::Invocation::Method->new( name => "bar", arguments => [ ] ),
	),
	undef,
	"base->bar",
);

is(
	$base_obj_box->responder_interface->dispatch(
		$base_obj_box,
		MO::Run::Invocation::Method->new( name => "elk", arguments => [ ] ),
	)->(),
	"moose",
	"base->elk",
);

is(
	$base_obj_box->responder_interface->dispatch(
		$base_obj_box,
		MO::Run::Invocation::Method->new( name => "elk", arguments => [ "val" ] ),
	)->(),
	"val",
	"base->elk('val')",
);

is(
	$base_obj_box->responder_interface->dispatch(
		$base_obj_box,
		MO::Run::Invocation::Method->new( name => "elk", arguments => [ ] ),
	)->(),
	"val",
	"base->elk",
);

is(
	$sub_obj_box->responder_interface->dispatch(
		$sub_obj_box,
		MO::Run::Invocation::Method->new( name => "foo", arguments => [ ] ),
	)->(),
	"foo",
	"sub->foo",
);

is(
	$sub_obj_box->responder_interface->dispatch(
		$sub_obj_box,
		MO::Run::Invocation::Method->new( name => "bar", arguments => [ ] ),
	)->(),
	"bar",
	"sub->bar",
);


