#!/usr/bin/perl

package MO::Compile::Class::SI;
use Moose;

use MO::Run::ResponderInterface::MethodTable;
use MO::Run::Method::Simple;
use MO::Compile::Layout::Simple;

use Tie::RefHash;

has superclass => (
	isa => "MO::Compile::Class::SI",
	is  => "ro",
);

has attributes => (
	isa => "HashRef",
	is  => "ro",
	default => sub { { } },
);

has regular_instance_methods => (
	isa => "HashRef",
	is  => "ro",
	default => sub { { } },
);

has class_methods => (
	isa => "HashRef",
	is  => "ro",
	default => sub { { } },
);

has layout => (
	isa => "MO::Compile::Layout::Simple",
	is  => "ro",
	lazy => 1,
	default => sub { $_[0]->_build_layout },
);

has _attr_fields => (
	isa => "HashRef",
	is  => "ro",
	lazy => 1,
	default => sub {
		tie my %hash, "Tie::RefHash";
		\%hash;
	},
);

sub _build_layout {
	my $self = shift;
	my $attrs = $self->all_attributes;

	my $attr_fields = $self->_attr_fields;

	%$attr_fields = (
		map { $_ => [ $_->fields ] } values %$attrs,
	);

	MO::Compile::Layout::Simple->new(
		class  => $self,
		fields => [ map { @$_ } values %$attr_fields ],
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

	my @fields = @{ $self->_attr_fields->{$attr} || [] };
	my @slots = $self->layout->get_slots( @fields );

	$attr->methods( $self, @slots );
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

sub class_interface {
	my $self = shift;

	my $layout = $self->layout;

	MO::Run::ResponderInterface::MethodTable->new(
		methods => {
			%{ $self->all_class_methods },
			create_instance => MO::Run::Method::Simple->new(
				body => sub {
					my ( $class, @params ) = @_;

					MO::Run::Responder::Object->new(
						object              => $class->layout->create_instance_structure( @params ),
						responder_interface => $class->instance_interface,
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
