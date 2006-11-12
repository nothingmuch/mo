#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Class::Inspector;

use ok "MO::Run::Aux";
use ok "MO::Emit::P5";
use ok "MO::Compile::Class::MI";
use ok "MO::Compile::Attribute::Simple";
use ok "MO::Compile::Class::Method::Constructor";
use ok "MO::Compile::Class::Method::Accessor";

$MO::Run::Aux::MO_NATIVE_RUNTIME = 1;

{
	my $base = MO::Compile::Class::MI->new(
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

}

{
	my $base = MO::Compile::Class::MI->new(
		attributes => [
		MO::Compile::Attribute::Simple->new(
			name    => "foo",
			private => 1,
		),
		],
	);

	my $sub = MO::Compile::Class::MI->new(
		superclasses => [ $base ],
		attributes => [
		MO::Compile::Attribute::Simple->new(
			name    => "foo",
			private => 1,
		),
		],
	);

	my $base_box = MO::Run::Aux::box( $base, $base->class_interface );
	my $sub_box = MO::Run::Aux::box( $sub, $sub->class_interface );

	can_ok( $_, "create_instance" ) for $base_box, $sub_box;

	my $base_obj = $base_box->create_instance;
	my $sub_obj = $sub_box->create_instance;	

	is( eval { $base_obj->foo }, undef, "bar->foo returns undef");
	ok( $@, "can't call ->foo" );

	# can't just make instance_methods, they'll be in main
	my $base_foo = eval q{
		package } . ref($base_obj) . q{;
		sub { shift->foo(@_) }
	};

	is( eval { $base_obj->$base_foo }, undef, "bar->foo returns undef");
	ok( !$@, "can call from it's own pkg" ) || diag $@;

	$base_obj->$base_foo( "bar" );

	is( eval { $base_obj->$base_foo }, "bar", "bar->foo returns undef");
	ok( !$@, "can call from it's own pkg" ) || diag $@;

	my $sub_foo = eval q{
		package } . ref($sub_obj). q{;
		sub { shift->foo(@_) }
	};

	$sub_obj->$base_foo("moose");
	$sub_obj->$sub_foo("elk");

	is( $sub_obj->$base_foo, "moose", "base::foo on sub is private" );
	is( $sub_obj->$sub_foo, "elk", "sub::foo on sub is private" );
}

