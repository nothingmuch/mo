#!/usr/bin/perl

package MO::Compile::Class::Method::Constructor;
use Moose;

with "MO::Compile::Method";

use MO::Compile::Method::Compiled;

use MO::Run::Aux;

sub name {}
has name => (
	isa => "Str",
	is  => "ro",
	required => 1,
);

has layout => (
	does => "MO::Compile::Layout",
	is   => "ro",
	required => 1,
);

has initializers => (
	isa => "ArrayRef",
	is  => "ro",
	default    => sub { [] },
	auto_deref => 1,
);

has responder_interface => (
	does => "MO::Run::Abstract::ResponderInterface",
	is   => "ro",
	required => 1,
);

sub compile {
	my ( $self, %params ) = @_;

	my $layout              = $self->layout;
	my @initializers        = $self->initializers;
	my $responder_interface = $self->responder_interface;

	return MO::Compile::Method::Simple::Compiled->new(
		body => sub {
			my ( $class, %params ) = @_;

			my @fields;

			push @fields, $_->params_to_fields( \%params ) for grep { $_->can("params_to_fields") } @initializers;

			my $object = $layout->create_instance_structure( fields => \@fields );

			my $boxed = MO::Run::Aux::box( $object, $responder_interface );

			$_->initialize_instance( $boxed, \%params ) for grep { $_->can("initialize_instance") } @initializers;

			return $boxed;
		}
	);
}

__PACKAGE__;

__END__
