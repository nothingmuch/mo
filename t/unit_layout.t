#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok "MO::Compile::Class::Layout::Hash";
use ok "MO::Compile::Field";

use MO::Compile::Class::SI;

# FIXME refactor this test into a higher order test, in MO::Test::LayoutBasic
# or something like that

{
	package StupidField;
	use Moose;

	with "MO::Compile::Field";

	sub name {}
	has name => (
		isa => "Str",
		is  => "ro",
		required => 1,
	);
}


my @fields = map {
	StupidField->new(
		name => $_,
	);
} qw/foo bar gorch/;

my $layout = MO::Compile::Class::Layout::Hash->new(
	fields => \@fields,
	class => MO::Compile::Class::SI->new, # any class, we don't really care
);

my ( $foo, $bar, $gorch ) = $layout->slots_for_fields(@fields);

my $instance = $layout->create_instance_structure;

ok( !$foo->is_initialized( $instance ), "foo slot not yet initialized" );

$foo->initialize( $instance );

ok( $foo->is_initialized( $instance ), "foo slot not initialized" );

$foo->clear( $instance );

ok( !$foo->is_initialized( $instance ), "foo slot uninitialized" );

$foo->initialize( $instance );

is( $foo->get_value( $instance ), undef, "no value even when initialized" );

$foo->set_value( $instance, "moose" );

is( $foo->get_value( $instance ), "moose", "set value" );

$foo->set_value( $instance, undef );

is( $foo->get_value( $instance ), undef, "value can be set to undef" );

$foo->clear( $instance );

ok( !$foo->is_initialized( $instance ), "foo slot uninitialized" );

$foo->initialize( $instance );

is( $foo->get_value( $instance ), undef, "no value even when initialized" );


