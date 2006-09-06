#!/usr/bin/perl

package MO::Compile::Class;
use Moose::Role;

use MO::Util::Collection;
use MO::Util::Collection::Merge;
use MO::Util::Collection::Shadow;
use MO::Util::Collection::Shadow::Accessor;
use MO::Run::ResponderInterface::MethodTable;
use MO::Run::MethodDefinition::Simple;
use MO::Compile::Role;

with "MO::Compile::Abstract::Class";

requires "layout_class";

has roles => (
	isa => "ArrayRef",
	is  => "rw",
	auto_deref => 1,
	default    => sub { [] },
);

has attributes => (
	isa => "MO::Util::Collection",
	is  => "rw",
	coerce  => 1,
	default => sub { MO::Util::Collection->new },
);

has regular_instance_methods => (
	isa => "MO::Util::Collection",
	is  => "rw",
	coerce  => 1,
	default => sub { MO::Util::Collection->new },
);

has class_methods => (
	isa => "MO::Util::Collection",
	is  => "rw",
	coerce  => 1,
	default => sub { MO::Util::Collection->new },
);

sub layout {
	my $self = shift;
	$self->_build_layout( map { $_->fields($self) } $self->all_attributes);
}

sub _build_layout {
	my ( $self, @fields ) = @_;

	$self->layout_class->new(
		class  => $self,
		fields => \@fields,
	);
}

sub merged_roles {
	my $self = shift;

	MO::Compile::Role->new(
		roles => [ $self->roles ],
	);
}

sub get_all_using_mro_shadowing {
	my ( $self, $accessor, @args ) = @_;

	my $attaching_accessor = $self->_attaching_accessor( $accessor, @args );

	my $shadower = MO::Util::Collection::Shadow::Accessor->new(
		accessor => $attaching_accessor,
	);

	MO::Util::Collection::Shadow->new->shadow(
		MO::Util::Collection->new( $shadower->shadow( $self->class_precedence_list ) ),
		MO::Util::Collection->new( $self->merged_roles->get_all_using_role_shadowing( $attaching_accessor ) ),
	)
}

sub get_all_using_mro {
	my ( $self, $accessor, @args ) = @_;

	my $attaching_accessor = $self->_attaching_accessor( $accessor, @args );

	return (
		(map { $_->$attaching_accessor->items } reverse $self->class_precedence_list),
		$self->merged_roles->get_all_using_role_inheritence($attaching_accessor),
	);
}

sub _attaching_accessor {
	my ( $self, $accessor, @args ) = @_;

	return sub {
		my $class_or_role = shift;
		$self->_attach_collection(
			$class_or_role,
			$class_or_role->$accessor(@args)
		);
	};
}

sub _attach_collection {
	my ( $self, $origin, $collection ) = @_;

	MO::Util::Collection->new(
		map {
			$_->can("attach")
				? $_->attach($origin)
		   		:  $_
		} $collection->items
	);
}

sub all_class_methods {
	my $self = shift;
	return (
		$self->all_regular_class_methods,
		$self->special_class_methods,
	);
}

sub all_regular_instance_methods {
	my $self = shift;
	$self->get_all_using_mro_shadowing( "regular_instance_methods" );
}

sub all_regular_class_methods {
	my $self = shift;
	$self->get_all_using_mro_shadowing( "class_methods" )
}

sub all_attributes_shadowed {
	my $self = shift;
	$self->get_all_using_mro_shadowed( "attributes" );
}

sub all_attributes {
	my $self = shift;
	$self->get_all_using_mro( "attributes" );
}

sub special_class_methods {
	my $self = shift;
	return (
		$self->constructor_method,
	);
}

sub all_instance_methods {
	my $self = shift;

	return (
		$self->all_attribute_instance_methods,
		$self->all_regular_instance_methods,
	);
}

# this is a bit of a hack, it applies shadowing to the methods, not the attrs
sub all_attribute_instance_methods {
	my $self = shift;

	my $attaching_accessor = $self->_attaching_accessor("attributes");

	$self->get_all_using_mro_shadowing( sub {
		my $ancestor = shift;

		my @attrs = $ancestor->$attaching_accessor->items;
		my @method_collections = map { $self->methods_of_attribute($_) } @attrs;
	
		# per ancestor all the accessors are merged symmetrically	
		MO::Util::Collection->new( MO::Util::Collection::Merge->new->merge( @method_collections ) );
	});
}

sub all_compiled_attributes {
	my $self = shift;
	map { $self->compile_attribute($_) } $self->all_attributes;
}

sub methods_of_attribute {
	my ( $self, $attr ) = @_;

	MO::Util::Collection->new(
		$self->compile_attribute( $attr )->methods,
	);
}

sub compile_attribute {
	my ( $self, $attr ) = @_;

	my @slots = $self->_attr_slots( $attr );

	return $attr->compile(
		class => $self,
		slots => \@slots,
	);
}

sub _attr_slots {
	my ( $self, $the_attr ) = @_;

	my @fields;
	my ( $from, $to );
	foreach my $attached_attr ( $self->all_attributes ) {
		if ( $attached_attr->attribute == $the_attr->attribute ) {
			$from = scalar @fields;
			push @fields, $attached_attr->fields($self);
			$to = $#fields;
		} else {
			push @fields, $attached_attr->fields($self);
		}
	}

	die "Can't compile slots for attribute " . $the_attr->name . ": it's not in the list of all attributes"
		unless defined $from and defined $to;

	( $self->layout->slots )[ $from .. $to ];
}

sub constructor_method {
	my $self = shift;

	my $layout              = $self->layout;
	my @compiled_attributes = $self->all_compiled_attributes;
	my $instance_interface  = $self->instance_interface;

	return MO::Compile::Method::Simple->new(
		name       => "create_instance",
		definition => MO::Run::MethodDefinition::Simple->new(
			body => sub {
				my ( $class, @params ) = @_;

				my $object = $layout->create_instance_structure;

				$_->initialize( $object, @params )
				for @compiled_attributes;

				MO::Run::Responder::Invocant->new(
					object              => $object,
					responder_interface => $instance_interface,
				);
			}
		),
	);
}

__PACKAGE__;

__END__
