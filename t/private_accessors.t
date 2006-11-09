#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok "MO::Compile::Class::MI";
use ok "MO::Compile::Attribute::Simple";
use ok "MO::Run::Invocation::Method";
use ok "MO::Run::Responder::Invocant";
use ok "MO::Run::Aux::Stack";

my $base = MO::Compile::Class::MI->new(
	attributes => [
		MO::Compile::Attribute::Simple->new(
			name    => "x",
			private => 1,
		),
	],
);

my $sub = MO::Compile::Class::MI->new(
	superclasses => [ $base ],
	attributes => [
		MO::Compile::Attribute::Simple->new(
			name    => "x",
			private => 1,
		),
	],
);


my $sub_box = MO::Run::Responder::Invocant->new(
	invocant            => $sub,
	responder_interface => $sub->class_interface,
);

my $sub_obj_box = $sub_box->responder_interface->dispatch(
	$sub_box,
	MO::Run::Invocation::Method->new( name => "create_instance", arguments => [ elk => "moose" ] ),
)->();

sub stack { MO::Run::Aux::Stack->new( items => [ @_ ] ) }

$sub_obj_box->responder_interface->dispatch(
	$sub_obj_box,
	MO::Run::Invocation::Method->new(
		name      => "x",
		arguments => ["foo"],
	),
	stack => stack($sub),
)->();

$sub_obj_box->responder_interface->dispatch(
	$sub_obj_box,
	MO::Run::Invocation::Method->new(
		name      => "x",
		arguments => ["bar"],
	),
	stack => stack($base),
)->();

is(
	$sub_obj_box->responder_interface->dispatch(
		$sub_obj_box,
		MO::Run::Invocation::Method->new(
			name      => "x",
			arguments => [],
		),
		stack => stack($sub),
	)->(),
	"foo",
	"private attr for sub",
);

is(
	$sub_obj_box->responder_interface->dispatch(
		$sub_obj_box,
		MO::Run::Invocation::Method->new(
			name      => "x",
			arguments => [],
		),
		stack => stack($base),
	)->(),
	"bar",
	"private attr for base",
);

