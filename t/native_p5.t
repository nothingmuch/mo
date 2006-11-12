#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Class::Inspector;

use ok "MO::Run::Aux";
use ok "MO::Compile::Class::SI";
use ok "MO::Compile::Attribute::Simple";
use ok "MO::Compile::Class::Method::Constructor";
use ok "MO::Compile::Class::Method::Accessor";

$MO::Run::Aux::MO_NATIVE_RUNTIME = 1;

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

my $class_box = MO::Run::Aux::box( $base, $base->class_interface );

can_ok( $class_box, "create_instance" );

my $obj = $class_box->create_instance;

is( $obj->elk, undef, "no elk" );

$obj->elk( "magic" );

is( $obj->elk, "magic", "magical elk fairy princess" );

is_deeply(
	[ sort @{Class::Inspector->methods( ref $obj ) || []} ],
	[ sort qw/elk foo/ ],
	"methods extracted using Class::Inspector",
);

