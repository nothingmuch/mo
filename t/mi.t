#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use t::stats;

use ok "MO::Compile::Class::MI";
use ok 'MO::Compile::Method::Simple';
use ok 'MO::Compile::Attribute::Simple';
use ok 'MO::Run::Aux';

t::stats->start(qw/construct runtime/);

my $base = MO::Compile::Class::MI->new();

my $point = MO::Compile::Class::MI->new(
	superclasses => [ $base ],
	instance_methods => [
		MO::Compile::Method::Simple->new(
			name       => "distance",
			definition => sub {
				my ( $self, $other_point ) = @_;
				die "stub";
			}
		),
	],
	attributes => [
		MO::Compile::Attribute::Simple->new(
			name => "x",
		),
		MO::Compile::Attribute::Simple->new(
			name => "y",
		),
	],
);

my $point3d = MO::Compile::Class::MI->new(
	superclasses => [ $point ],
	attributes   => [
		MO::Compile::Attribute::Simple->new(
			name => "z",
		),
	],
);

my $colorful = MO::Compile::Class::MI->new(
	superclasses => [ $base ],
	attributes => [
		MO::Compile::Attribute::Simple->new(
			name => "color",
		),
	],
);

my $colorful_point = MO::Compile::Class::MI->new(
	superclasses => [ $point, $colorful ],
);

my $colorful_point3d = MO::Compile::Class::MI->new(
	superclasses => [ $point3d, $colorful ],
);

t::stats->finish("construct");

t::stats->start(qw/mro meta_calc/);

is_deeply(
	[ $colorful_point->class_precedence_list ],
	[ $colorful_point, $point, $colorful, $base ],
	"mro linearization",
);

is_deeply(
	[ map { "$_" } $colorful_point3d->class_precedence_list ],
	[ map { "$_" } $colorful_point3d, $point3d, $point, $colorful, $base ],
	"mro linearization",
);

is_deeply(
	[ sort map { $_->name } $colorful_point->all_attributes ],
	[ sort qw/x y color/ ],
	"inherited accessors of mi",
);

is_deeply(
	[ sort map { $_->name } $colorful_point3d->all_attributes ],
	[ sort qw/x y z color/ ],
	"inherited accessors of deeper mi",
);

t::stats->finish("mro");

my $colorful_point3d_box = MO::Run::Aux::box( $colorful_point3d, $colorful_point3d->class_interface );

my $colorful_point3d_obj_box = MO::Run::Aux::method_call(
	$colorful_point3d_box,
	"create_instance",
	x => 1,
	y => 2,
	z => 3,
	color => "shiny",
);

t::stats->finish("meta_calc");

t::stats->start("dispatch");

is(
	MO::Run::Aux::method_call( $colorful_point3d_obj_box, "color" ),
	"shiny",
	"point.color",
);

MO::Run::Aux::method_call( $colorful_point3d_obj_box, "color", "orange" );

is(
	MO::Run::Aux::method_call( $colorful_point3d_obj_box, "color" ),
	"orange",
	"point.color",
);

t::stats->finish(qw/dispatch runtime/);
