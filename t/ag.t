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

# a shorthand form for invoking named methods
# like the -> operator
sub call ($$$;@) {
	my ( $obj, $method, $caller, @args ) = @_;
	no warnings;

	my $thunk = $obj->responder_interface->dispatch(
		$obj,
		MO::Run::Invocation::Method->new(
			name      => $method,
			arguments => \@args,
			caller    => $caller,
		),
	);

	die "No such method: $method on inv $obj" unless $thunk;

	$thunk->();
}

my $weak_ag_instance; # caller in closures
my $avg_diff_ag;
$avg_diff_ag = MO::Compile::AttributeGrammar->new(
	root_attributes => [
		MO::Compile::AttributeGrammar::Attribute::Synthesized->new(
			method => MO::Compile::Method::Simple->new(
				name 	   => "average",
				definition => sub {
					my $self = shift;
					my $total = call( $self, "total", $avg_diff_ag );
					my $count = call( $self, "count", $avg_diff_ag );
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
		$weak_ag_instance = MO::Compile::AttributeGrammar::Instance->new(
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
							my $avg = call( $self, "average", $weak_ag_instance );
							call( $child, "average", $weak_ag_instance, $avg );
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
								map { call($_, "count", $weak_ag_instance) }
								@{ call($self, "children", $weak_ag_instance) },
							);
						},
					),
				),
				MO::Compile::AttributeGrammar::Attribute::Synthesized->new(
					method => MO::Compile::Method::Simple->new(
						name       => "total",
						definition => sub {
							my $self = shift;
							call($self, "value", $weak_ag_instance)
								+
							sum(
								0,
								map { call($_, "total", $weak_ag_instance) }
								@{ call($self, "children", $weak_ag_instance) },
							);
						},
					),
				),
				MO::Compile::AttributeGrammar::Attribute::Synthesized->new(
					method => MO::Compile::Method::Simple->new(
						name       => "diff",
						definition => sub {
							my $self = shift;
							call($self, "value", $weak_ag_instance)
								-
							call($self, "average", $weak_ag_instance);
						}
					),
				),
				MO::Compile::AttributeGrammar::Attribute::Synthesized->new(
					method => MO::Compile::Method::Simple->new(
						name       => "diff_structure",
						definition => sub {
							my $self = shift;
							my $class = $tree_class_inv; # call($self, "meta", $weak_ag_instance);
							call( $class, "create_instance", $weak_ag_instance,
								value => call($self, "diff", $weak_ag_instance),
								children => [
									map { call($_, "diff_structure", $weak_ag_instance) }
										@{ call($self, "children", $weak_ag_instance) },
								],
							);
						}
					),
				),
			],
		),
	],
);

weaken($weak_ag_instance);

$tree_class_inv = MO::Run::Responder::Invocant->new(
	invocant            => $tree_class,
	responder_interface => $tree_class->class_interface,
);

my $tree = call( $tree_class_inv, "create_instance", undef,
	value => 10,
	children => [
		call( $tree_class_inv, "create_instance", undef,
			value => 5,
			children => [],
		),
		call( $tree_class_inv, "create_instance", undef,
			value => 15,
			children => [],
		),
	],
);

is( eval { call($tree, "count", undef) }, undef, "can't call count on tree" );

my $ag_inv = MO::Run::Responder::Invocant->new(
	invocant            => $avg_diff_ag,
	responder_interface => $avg_diff_ag->responder_interface,
);

my $ag = call( $ag_inv, "create_instance", undef,
	root => $tree,
);

is( call($ag, "count",   undef), 3, "count synthesized attr" );
is( call($ag, "total",   undef), 30, "total synthesized attr" );
is( call($ag, "average", undef), 10, "average root synthesized attr" );

ok( my $diff_tree = call( $ag, "diff_structure", undef ), "diff_structure" );

is( call($diff_tree, "value", undef), 0, "diff from average is right" );
my @children = @{ call($diff_tree, "children", undef) || [] };
is( scalar(@children), 2, "two children" );
is( eval { call($children[0], "value", undef) }, -5, "child 1 diff from average is right" );
is( eval { call($children[1], "value", undef) }, 5,  "child 2 diff from average is right" );
