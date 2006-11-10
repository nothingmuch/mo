#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Scalar::Util qw/weaken/;
use List::Util qw/sum/;

use ok 'MO::Compile::AttributeGrammar';
use ok 'MO::Compile::AttributeGrammar::Instance';
use ok 'MO::Compile::AttributeGrammar::Attribute::Synthesized';
use ok 'MO::Compile::AttributeGrammar::Attribute::Inherited';
use ok 'MO::Compile::AttributeGrammar::Attribute::Bestowed';
use ok 'MO::Compile::Class::MI';
use ok 'MO::Compile::Attribute::Simple';
use ok 'MO::Compile::Method::Simple';
use ok 'MO::Run::Responder::Invocant';
use ok 'MO::Run::Invocation::Method';
use ok 'MO::Run::Aux' => qw/method_call/;

# a shorthand form for invoking named methods
# like the -> operator

my $avg_diff_ag = MO::Compile::AttributeGrammar->new(
	root_attributes => [
		MO::Compile::AttributeGrammar::Attribute::Synthesized->new(
			method => MO::Compile::Method::Simple->new(
				name 	   => "average",
				definition => sub {
					my $self = shift;
					my $total = method_call( $self, "total" );
					my $count = method_call( $self, "count" );
					return $total / $count;
				},
			),
		),
	],
);

my $tree_class_inv;
my $tree_class = MO::Compile::Class::MI->new(
	attributes => [
		MO::Compile::Attribute::Simple->new( name => "value" ),
		MO::Compile::Attribute::Simple->new( name => "children" ),
	],
	attribute_grammars => [
		MO::Compile::AttributeGrammar::Instance->new(
			attribute_grammar => $avg_diff_ag,
			inherited_attributes   => [
				MO::Compile::AttributeGrammar::Attribute::Inherited->new(
					name => "average",
				),
			],
			bestowed_attributes => [
				MO::Compile::AttributeGrammar::Attribute::Bestowed->new(
					method => MO::Compile::Method::Simple->new(
						name 	   => "average",
						definition => sub {
							my ( $self, $child ) = @_;
							my $avg = method_call( $self, "average" );
							method_call( $child, "average", $avg );
						}
					),
				),
			],
			synthesized_attributes => [
				MO::Compile::AttributeGrammar::Attribute::Synthesized->new(
					method => MO::Compile::Method::Simple->new(
						name       => "count",
						definition => sub {
							my $self = shift;
							1 + sum(
								0,
								map { method_call( $_, "count" ) }
									@{ method_call( $self, "children" ) },
							);
						},
					),
				),
				MO::Compile::AttributeGrammar::Attribute::Synthesized->new(
					method => MO::Compile::Method::Simple->new(
						name       => "total",
						definition => sub {
							my $self = shift;
							method_call( $self, "value" )
								+
							sum(
								0,
								map { method_call( $_, "total" ) }
									@{ method_call( $self, "children" ) },
							);
						},
					),
				),
				MO::Compile::AttributeGrammar::Attribute::Synthesized->new(
					method => MO::Compile::Method::Simple->new(
						name       => "diff",
						definition => sub {
							my $self = shift;
							method_call( $self, "value" )
								-
							method_call( $self, "average" );
						}
					),
				),
				MO::Compile::AttributeGrammar::Attribute::Synthesized->new(
					method => MO::Compile::Method::Simple->new(
						name       => "diff_structure",
						definition => sub {
							my $self = shift;
							my $class = $tree_class_inv; # call($self, "meta");
							method_call( $class, "create_instance",
								value    => method_call($self, "diff" ),
								children => [
									map { method_call($_, "diff_structure" ) }
										@{ method_call($self, "children" ) },
								],
							);
						}
					),
				),
			],
		),
	],
);

$tree_class_inv = MO::Run::Responder::Invocant->new(
	invocant            => $tree_class,
	responder_interface => $tree_class->class_interface,
);

my $tree = method_call( $tree_class_inv, "create_instance",
	value => 10,
	children => [
		method_call( $tree_class_inv, "create_instance",
			value => 5,
			children => [],
		),
		method_call( $tree_class_inv, "create_instance",
			value => 15,
			children => [],
		),
	],
);

is( eval { method_call($tree, "count") }, undef, "can't call count on tree" );

my $ag_inv = MO::Run::Responder::Invocant->new(
	invocant            => $avg_diff_ag,
	responder_interface => $avg_diff_ag->responder_interface,
);

my $ag = method_call( $ag_inv, "create_instance",
	root => $tree,
);

is( method_call($ag, "count"), 3, "count synthesized attr" );
is( method_call($ag, "total"), 30, "total synthesized attr" );
is( method_call($ag, "average"), 10, "average root synthesized attr" );

ok( my $diff_tree = method_call( $ag, "diff_structure" ), "diff_structure" );

is( method_call($diff_tree, "value"), 0, "diff from average is right" );
my @children = @{ method_call($diff_tree, "children") || [] };
is( scalar(@children), 2, "two children" );
is( eval { method_call($children[0], "value") }, -5, "child 1 diff from average is right" );
is( eval { method_call($children[1], "value") }, 5,  "child 2 diff from average is right" );

