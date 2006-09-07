#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'MO::Run::ResponderInterface::MethodTable';
use ok 'MO::Run::Responder::Invocant';
use ok 'MO::Run::Invocation::Method';
use ok 'MO::Run::MethodDefinition::Simple';

sub does_ok ($$;$) {
	my ( $inv, $role, $desc ) = @_;
	$desc ||= "$inv does $role";
	ok( $inv->can("does") && $inv->does($role), $desc );
}

does_ok( "MO::Run::Invocation::Method", "MO::Run::Abstract::Invocation" );
does_ok( "MO::Run::Responder::Invocant", "MO::Run::Abstract::Responder" );
does_ok( "MO::Run::ResponderInterface::MethodTable", "MO::Run::Abstract::ResponderInterface" );

my $foo = MO::Run::Invocation::Method->new(
	name      => "foo",
	arguments => [ "bar" ],
);

my $bar = MO::Run::Invocation::Method->new(
	name      => "bar",
	arguments => [ "bar" ],
);

my $i = MO::Run::ResponderInterface::MethodTable->new(
	methods => {
		foo => MO::Run::MethodDefinition::Simple->new(
			body => sub {
				my ( $self, @args ) = @_;
				return "moose: " . $self->invocant . " @args";
			},
		),
	},
);

my $obj = {};

my $obj_box = MO::Run::Responder::Invocant->new(
	invocant            => "<The Invocant>",
	responder_interface => $i,
);


can_ok( $i, "methods" );

can_ok( $i, "dispatch" );

my $thunk = $obj_box->responder_interface->dispatch(
	$obj_box,
	$foo,
);

ok( $thunk, "dispatch yielded a thunk" );

is( ref($thunk), "CODE", "thunk is a code ref" );

like( $thunk->(), qr/^moose: <The Invocant> bar$/, "thunk evaluates correctly" );

ok(
	!$obj_box->responder_interface->dispatch(
		$obj_box,
		$bar,
	),
	"can't dispatch without method def",
);
