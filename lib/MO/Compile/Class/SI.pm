#!/usr/bin/perl

package MO::Compile::Class::SI;
use Moose;

use MO::Run::ResponderInterface::MethodTable;
use MO::Run::Method::Simple;
use MO::Compile::Layout::Simple;

has superclass => (
	isa => "MO::Compile::Class::SI",
	is  => "rw",
);

has attributes => (
	isa => "HashRef",
	is  => "rw",
	default => sub { { } },
);

has regular_instance_methods => (
	isa => "HashRef",
	is  => "rw",
	default => sub { { } },
);

has class_methods => (
	isa => "HashRef",
	is  => "rw",
	default => sub { { } },
);

sub layout {
	my $self = shift;
	$self->_build_layout( map { $_->fields } values %{ $self->all_attributes } );
}

sub _build_layout {
	my ( $self, @fields ) = @_;

	MO::Compile::Layout::Simple->new(
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
	return { map { %{ $_->$accessor(@args) } } reverse $self->class_precedence_list };
}

sub all_class_methods {
	my $self = shift;
	$self->_get_all( "class_methods" );	
}

sub all_regular_instance_methods {
	my $self = shift;
	$self->_get_all( "regular_instance_methods" );
}

sub all_accessors {
	my $self = shift;
	my $attrs = $self->all_attributes;
	return {
		map { %{ $self->methods_of_attr( $_ ) } } values %$attrs,
	};
}

sub methods_of_attr {
	my ( $self, $attr ) = @_;

	my $run_attr = $self->compile_attribute( $attr );

	$run_attr->methods;
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
	foreach my $attr ( values %{ $self->all_attributes } ) {
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

	return {
		%{ $self->all_accessors },
		%{ $self->all_regular_instance_methods },
	}
}

sub all_attributes {
	my $self = shift;
	$self->_get_all( "attributes" );
}

sub all_compiled_attributes {
	my $self = shift;
	my $attrs = $self->all_attributes;
	return { map { $_ => $self->compile_attribute($attrs->{$_}) } keys %$attrs };
}

sub class_interface {
	my $self = shift;

	my $layout              = $self->layout;
	my @compiled_attributes = values %{ $self->all_compiled_attributes };
	my $instance_interface  = $self->instance_interface;

	MO::Run::ResponderInterface::MethodTable->new(
		methods => {
			%{ $self->all_class_methods },
			create_instance => MO::Run::Method::Simple->new(
				body => sub {
					my ( $class, @params ) = @_;

					my $object = $layout->create_instance_structure;

					$_->initialize( $object, @params )
						for @compiled_attributes;

					MO::Run::Responder::Object->new(
						object              => $object,
						responder_interface => $instance_interface,
					);
				}
			),
		},
	);
}

sub instance_interface {
	my $self = shift;

	MO::Run::ResponderInterface::MethodTable->new(
		methods => $self->all_instance_methods,
	);
}

__PACKAGE__;

__END__
