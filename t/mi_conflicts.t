#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok "MO::Compile::Class::MI";
use ok 'MO::Compile::Attribute::Simple';

use Test::MockObject::Extends;

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



my $mo = Test::MockObject::Extends->new(
	MO::Compile::Attribute::Simple->new(
		name => "y",
	),
);

$mo->mock( compile => sub {
	my ( $self, @args ) = @_;
	MO::Compile::Attribute::Simple->new(
		name => "x",
	)->compile(@args);
});

	use Data::Dumper;
eval {
	warn Dumper( MO::Compile::Class::MI->new(
		attributes => [
			MO::Compile::Attribute::Simple->new(
				name => "x",
			),
			$mo,
		],
	)->instance_interface );
};

ok( $@, "can't create class with accessors that have conflicting methods" );
like( $@, qr/merged.*name/, "the right error" );

