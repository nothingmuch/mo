#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok "MO::Compile::Class::MI";
use ok 'MO::Compile::Attribute::Simple';

eval {
	MO::Compile::Class::MI->new(
		attributes => [
			MO::Compile::Attribute::Simple->new(
				name => "x",
			),
			MO::Compile::Attribute::Simple->new(
				name => "x",
			),
		],
	);
};

ok( $@, "can't create class with two accessors of the same name" );
like( $@, qr/name conflict/, "the right error" );


eval {
	MO::Compile::Class::MI->new(
		attributes => [
			MO::Compile::Attribute::Simple->new(
				name => "x",
			),
			MO::Compile::Attribute::Simple->new(
				name          => "y",
				accessor_name => "x",
			),
		],
	)->instance_interface;
};

ok( $@, "can't create class with accessors that have conflicting methods" );
like( $@, qr/merged.*name/, "the right error" );





my @slots = MO::Compile::Class::MI->new(
	superclasses => [
	MO::Compile::Class::MI->new(
		attributes => [
			MO::Compile::Attribute::Simple->new(
				name    => "x",
				private => 1,
				accessor_name => "moosen",
			),
		],
	),
	MO::Compile::Class::MI->new(
		attributes => [
			MO::Compile::Attribute::Simple->new(
				name    => "x",
				private => 1,
				accessor_name => "elken",
			),
		],
	),
	],
)->layout->slots;

is( @slots, 2, "two slots" );
my @slot_names = (map { $_->name } @slots)[0, 1];
like( $_, qr/^private:.*?::x$/, "slot is correctly named" ) for @slot_names;
cmp_ok( $slot_names[0], 'ne', $slot_names[1], "slot names are different" );
