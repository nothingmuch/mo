#!/usr/bin/perl

package MO::Compile::Class;
use Moose::Role;

use MO::Util::Collection;
use MO::Util::Collection::Merge;
use MO::Util::Collection::Shadow::Accessor;
use MO::Run::ResponderInterface::MethodTable;
use MO::Run::MethodDefinition::Simple;

with "MO::Compile::Abstract::Class";

requires "layout_class";

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
	$self->_build_layout( map { $_->fields } $self->all_attributes);
}

sub _build_layout {
	my ( $self, @fields ) = @_;

	$self->layout_class->new(
		class  => $self,
		fields => \@fields,
	);
}

sub get_all_using_mro_shadowing {
	my ( $self, $accessor, @args ) = @_;

	my $shadower = MO::Util::Collection::Shadow::Accessor->new( accessor => $accessor );

	$shadower->shadow( $self->class_precedence_list );
}

sub get_all_using_mro {
	my ( $self, $accessor, @args ) = @_;

	map { $_->$accessor->items } reverse $self->class_precedence_list;
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

sub all_attribute_instance_methods {
	my $self = shift;

	my @collections = map { $self->methods_of_attr( $_ ) } $self->all_attributes;
	MO::Util::Collection::Merge->new->merge( @collections );
}

sub all_compiled_attributes {
	my $self = shift;
	map { $self->compile_attribute($_) } $self->all_attributes;
}

sub methods_of_attr {
	my ( $self, $attr ) = @_;

	my $run_attr = $self->compile_attribute( $attr );

	MO::Util::Collection->new(
		$run_attr->methods
	);
}

sub compile_attribute {
	my ( $self, $attr ) = @_;

	my @slots = $self->_attr_slots( $attr );

	return $attr->compile( class => $self, slots => \@slots );
}

sub _attr_slots {
	my ( $self, $the_attr ) = @_;
	
	my @fields;
	my ( $from, $to );
	foreach my $attr ( $self->all_attributes ) {
		if ( $attr == $the_attr ) {
			$from = scalar @fields;
			push @fields, $attr->fields;
			$to = $#fields;
		} else {
			push @fields, $attr->fields;
		}
	}

	die unless defined $from and defined $to;

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
