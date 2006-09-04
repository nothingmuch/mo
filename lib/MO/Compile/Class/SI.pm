#!/usr/bin/perl

package MO::Compile::Class::SI;
use Moose;

use MO::Util::Collection;
use MO::Util::Collection::Shadow;
use MO::Util::Collection::Merge;
use MO::Run::ResponderInterface::MethodTable;
use MO::Run::MethodDefinition::Simple;
use MO::Compile::Class::SI::Layout::Hash;

{
	package MO::Compile::Class::SI::Shadow;
	use Moose;
	extends 'MO::Util::Collection::Shadow';

	has accessor => (
		isa => "Str",
		is  => "rw",
		required => 1,
	);

	sub collection {
		my ( $self, $item ) = @_;
		my $accessor = $self->accessor;
		$item->$accessor;
	}
}

has superclass => (
	isa => "MO::Compile::Class::SI",
	is  => "rw",
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
	$self->_build_layout( map { $_->fields } $self->all_attributes);
}

sub _build_layout {
	my ( $self, @fields ) = @_;

	MO::Compile::Class::SI::Layout::Hash->new(
		class  => $self,
		fields => \@fields,
	);
}

sub class_precedence_list {
	my $self = shift;
	
	if ( my $superclass = $self->superclass ) {
		return ( $self, $superclass->class_precedence_list );
	} else {
		return $self;
	}
}

sub _get_all {
	my ( $self, $accessor, @args ) = @_;
	MO::Compile::Class::SI::Shadow->new( accessor => $accessor )->shadow( $self->class_precedence_list );
}

sub all_class_methods {
	my $self = shift;
	$self->_get_all( "class_methods" );	
}

sub all_regular_instance_methods {
	my $self = shift;
	$self->_get_all( "regular_instance_methods" );
}

sub all_attribute_instance_methods {
	my $self = shift;

	my @collections = map { $self->methods_of_attr( $_ ) } $self->all_attributes;
	MO::Util::Collection::Merge->new->merge( @collections );
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

sub all_instance_methods {
	my $self = shift;

	return (
		$self->all_attribute_instance_methods,
		$self->all_regular_instance_methods,
	);
}

sub all_attributes {
	my $self = shift;
	$self->_get_all( "attributes" );
}

sub all_compiled_attributes {
	my $self = shift;
	map { $self->compile_attribute($_) } $self->all_attributes;
}

sub class_interface {
	my $self = shift;

	my @interface = (
		$self->all_class_methods,
		$self->constructor,
	);

	MO::Run::ResponderInterface::MethodTable->new(
		methods => { map { $_->name => $_->definition } @interface },
	);
}

sub constructor {
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

sub instance_interface {
	my $self = shift;

	MO::Run::ResponderInterface::MethodTable->new(
		methods => { map { $_->name => $_->definition } $self->all_instance_methods },
	);
}

__PACKAGE__;

__END__
