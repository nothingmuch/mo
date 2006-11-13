#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok "MO::Compile::Class::MI";
use ok "MO::Compile::Method::Simple";
use ok "MO::Run::Invocation::Method";
use ok "MO::Run::Responder::Invocant";
use ok "MO::Run::Aux::Stack";
use ok "MO::Run::Aux";

$MO::Run::MO_NATIVE_RUNTIME = 0;

my $base = MO::Compile::Class::MI->new(
	instance_methods => [
		MO::Compile::Method::Simple->new(
			name       => "foo",
			definition => sub { "foo" },
		),
	],
	private_instance_methods => [
		MO::Compile::Method::Simple->new(
			name       => "foo",
			definition => sub { "base::foo" },
		),
	],
);

my $sub = MO::Compile::Class::MI->new(
	superclasses => [ $base ],
	private_instance_methods => [
		MO::Compile::Method::Simple->new(
			name       => "foo",
			definition => sub { "sub::foo" },
		),
	],
);

my $other = MO::Compile::Class::MI->new();

my $sub_box = MO::Run::Responder::Invocant->new(
	invocant            => $sub,
	responder_interface => $sub->class_interface,
);

sub stack { MO::Run::Aux::Stack->new( items => [ @_ ] ) }

my $sub_obj_box = $sub_box->responder_interface->dispatch(
	$sub_box,
	MO::Run::Invocation::Method->new( name => "create_instance", arguments => [ elk => "moose" ] ),
)->();

is(
	$sub_obj_box->responder_interface->dispatch(
		$sub_obj_box,
		MO::Run::Invocation::Method->new(
			name      => "foo",
			arguments => [],
		),
		stack => stack($sub),
	)->(),
	"sub::foo",
	"private dispatch from sub",
);

is(
	$sub_obj_box->responder_interface->dispatch(
		$sub_obj_box,
		MO::Run::Invocation::Method->new(
			name      => "foo",
			arguments => [],
		),
		stack => stack($base),
	)->(),
	"base::foo",
	"private dispatch from base",
);

is(
	$sub_obj_box->responder_interface->dispatch(
		$sub_obj_box,
		MO::Run::Invocation::Method->new(
			name      => "foo",
			arguments => [],
		),
		stack => stack($other),
	)->(),
	"foo",
	"public dispatch",
);

