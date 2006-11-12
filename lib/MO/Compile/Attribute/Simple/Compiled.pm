#!/usr/bin/perl

package MO::Compile::Attribute::Simple::Compiled;
use Moose;

with "MO::Compile::Attribute::Compiled";

use MO::Compile::Method::Simple;
use MO::Compile::Class::Method::Accessor;

BEGIN {

has attribute => (
	isa => "MO::Compile::Attribute::Simple",
	is  => "ro",
	handles => [ qw/name accessor_name private/ ],
);

}

sub target {}
has target => (
	does => "MO::Compile::Class",
	is   => "ro",
);

sub origin {}
has origin => (
	does => "MO::Compile::Origin",
	is   => "ro",
);

sub slots {}
has slots => (
	isa => "ArrayRef",
	is  => "ro",
	auto_deref => 1,
);

sub initialize_instance {
	my ( $self, $responder, %params ) = @_;

	my $slot = $self->slots->[0];

	my $instance = $responder->invocant;

	$slot->initialize( $instance ); # lazy accessors may skip this, # FIXME unbox macro

	if ( exists $params{ $self->name } ) {
		$slot->set_value( $instance, $params{ $self->name } );
	};
}

sub methods {
	my $self = shift;

	unless ( $self->private ) {
		return $self->_generate_accessor_method;
	} else {
		return;
	}
}

sub private_methods {
	my $self = shift;

	if ( $self->private ) {
		return $self->_generate_accessor_method;
	} else {
		return;
	}
}

sub slot {
	my $self = shift;

	my @slots = $self->slots;

	warn "Attribute $self has more than one slot, but the generated accessor will only use the first one" if @slots > 1;

	return $slots[0];
}

sub _generate_accessor_method {
	my $self = shift;

	my $method = MO::Compile::Class::Method::Accessor->new(
		name      => $self->accessor_name,
		slot      => $slot,
		attribute => $self,
	);

	return $method->attach( $self->origin );
}


__PACKAGE__;

__END__
