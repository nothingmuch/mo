#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use ok 'MO::Compile::Class::MI';
use ok 'MO::Compile::Role';
use ok 'MO::Compile::Method::Simple';
use ok 'MO::Compile::Attribute::Simple';

{
	my $with_conflict = MO::Compile::Class::MI->new(
		roles => [
			MO::Compile::Role->new(
				instance_methods => [
					MO::Compile::Method::Simple->new(
						name       => "foo",
						definition => sub { "foo" },
					),
				],
			),
			MO::Compile::Role->new(
				instance_methods => [
					MO::Compile::Method::Simple->new(
						name       => "foo",
						definition => sub { "foo2" },
					),
				],
			),
		],
	);

	my @methods = $with_conflict->all_instance_methods;
	is( @methods, 1, "one method" );
	isa_ok( $methods[0], "MO::Compile::Composable::Symmetric::Conflict" );
}

{
	my $no_conflict = MO::Compile::Class::MI->new(
		roles => [
			MO::Compile::Role->new(
				instance_methods => [
					MO::Compile::Method::Simple->new(
						name       => "foo",
						definition => sub { "foo" },
					),
				],
			),
			MO::Compile::Role->new(
				instance_methods => [
					MO::Compile::Method::Simple->new(
						name       => "foo2",
						definition => sub { "foo2" },
					),
				],
			),
		],
	);

	my @methods = $no_conflict->all_instance_methods;
	is( @methods, 2, "one method" );
	is_deeply(
		[ sort map { $_->name } @methods ],
		[ sort qw/foo foo2/ ],
		"methods from roles merged",
	);
}

{
	my $shadowed = MO::Compile::Class::MI->new(
		roles => [
			MO::Compile::Role->new(
				instance_methods => [
					MO::Compile::Method::Simple->new(
						name       => "foo",
						definition => sub { "foo" },
					),
				],
				roles => [
					MO::Compile::Role->new(
						instance_methods => [
							MO::Compile::Method::Simple->new(
								name       => "foo",
								definition => sub { "foo2" },
							),
							MO::Compile::Method::Simple->new(
								name       => "bar",
								definition => sub { "bar" },
							),
						],
					),
				],
			),
		],
	);

	my @methods = $shadowed->all_instance_methods;
	is( @methods, 2, "two methods" );
	is_deeply(
		[ sort map { $_->name } @methods ],
		[ sort qw/foo bar/ ],
		"methods from roles merged",
	);

	my $foo = ( grep { $_->name eq "foo" } @methods )[0];

	is( $foo->definition->body->(), "foo", "the right foo shadowed the wrong one" );
}

{
	my $shadowed = MO::Compile::Class::MI->new(
		roles => [
			MO::Compile::Role->new(
				attributes => [
					MO::Compile::Attribute::Simple->new(
						name => "foo",
					),
				],
				roles => [
					MO::Compile::Role->new(
						attributes => [
							MO::Compile::Attribute::Simple->new(
								name => "foo",
							),
						],
					),
				],
			),
		],
	);

	my @methods = $shadowed->all_instance_methods;
	is( @methods, 1, "one methods" );

	is( $methods[0]->name, "foo", "with the right name" ); # FIXME when we have Method::Accessor make sure the ->attribute is the right one

	my @attrs = $shadowed->all_attributes;

	is( @attrs, 2, "two attrs" );
	is_deeply(
		[ map { $_->name } @attrs ],
		[ qw/foo foo/ ],
		"with the same name",
	);
}

{
	my $no_conflict = MO::Compile::Class::MI->new(
		roles => [
			MO::Compile::Role->new(
				attributes => [
					MO::Compile::Attribute::Simple->new(
						name => "foo",
					),
				],
			),
			MO::Compile::Role->new(
				attributes => [
					MO::Compile::Attribute::Simple->new(
						name => "bar",
					)
				],
			),
		],
	);

	my @methods = $no_conflict->all_instance_methods;
	is( @methods, 2, "two methods" );
	is_deeply(
		[ sort map { $_->name } @methods ],
		[ sort qw/foo bar/ ],
		"methods from roles merged",
	);

	my @attrs = $no_conflict->all_attributes;

	is( @attrs, 2, "two attrs" );
	is_deeply(
		[ sort map { $_->name } @attrs ],
		[ sort qw/foo bar/ ],
		"attrs from roles merged",
	);
}

{
	my $with_conflict = MO::Compile::Class::MI->new(
		roles => [
			MO::Compile::Role->new(
				attributes => [
					MO::Compile::Attribute::Simple->new(
						name => "foo",
					),
				],
			),
			MO::Compile::Role->new(
				attributes => [
					MO::Compile::Attribute::Simple->new(
						name          => "foo",
						accessor_name => "bar",
					)
				],
			),
		],
	);

	my @methods = $with_conflict->all_instance_methods;
	is( @methods, 2, "two methods" );
	is_deeply(
		[ sort map { $_->name } @methods ],
		[ sort qw/foo bar/ ],
		"methods from roles merged",
	);

	my @attrs = $with_conflict->all_attributes;

	is( @attrs, 2, "two attrs" );
	is_deeply(
		[ sort map { $_->name } @attrs ],
		[ sort qw/foo foo/ ],
		"attrs from roles merged",
	);
}

{
	my $with_conflict = MO::Compile::Class::MI->new(
		roles => [
			MO::Compile::Role->new(
				attributes => [
					MO::Compile::Attribute::Simple->new(
						name => "foo",
					),
				],
			),
			MO::Compile::Role->new(
				attributes => [
					MO::Compile::Attribute::Simple->new(
						name          => "bar",
						accessor_name => "foo",
					)
				],
			),
		],
	);

	my @methods = $with_conflict->all_instance_methods;
	is( @methods, 1, "one method" );
	isa_ok( $methods[0], "MO::Compile::Composable::Symmetric::Conflict" );

	my @attrs = $with_conflict->all_attributes;

	is( @attrs, 2, "two attrs" );
	is_deeply(
		[ sort map { $_->name } @attrs ],
		[ sort qw/foo bar/ ],
		"attrs from roles merged",
	);

	throws_ok {
		$with_conflict->filter_composition_failures( @methods );
	} qr/^Composition failures in .*?Symmetric composition error over key 'foo'/s, "composition error thrown";
}
