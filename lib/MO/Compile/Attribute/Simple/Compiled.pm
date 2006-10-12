#!/usr/bin/perl

package MO::Compile::Attribute::Simple::Compiled;
use Moose;

with "MO::Compile::Attribute::Compiled";

use MO::Compile::Method::Simple;

BEGIN {

has attribute => (
	isa => "MO::Compile::Attribute::Simple",
	is  => "ro",
	handles => [ qw/name accessor_name private/ ],
);

}

has target => (
	does => "MO::Compile::Class",
	is   => "ro",
);

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

sub initialize {
	my ( $self, $instance, %params ) = @_;
	
	my $slot = $self->slots->[0];

	$slot->initialize( $instance ); # lazy accessors may skip this

	if ( exists $params{ $self->name } ) {
		$slot->set_value( $instance, $params{ $self->name } );
	};
}

sub accessor_body {
	my ( $self, $slot ) = @_;

	return sub {
		my ( $instance, @args ) = @_;

		if ( @args ) {
			return $slot->set_value( $instance->invocant, @args );
		} else {
			return $slot->get_value( $instance->invocant );
		}
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

sub _generate_accessor_method {
	my $self = shift;

	my $slot = ( $self->slots )[0];

	return MO::Compile::Method::Simple->new(
		name       => $self->accessor_name,
		definition => $self->accessor_body($slot),
	);
}


__PACKAGE__;

__END__
