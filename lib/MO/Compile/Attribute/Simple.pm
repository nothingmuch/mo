#!/usr/bin/perl

package MO::Compile::Attribute::Simple;
use Moose;

use MO::Compile::Field::Simple;
use MO::Run::Method::Simple;

has name => (
	isa => "Str",
	is  => "ro",
);

sub methods {
	my ( $self, $class, @slots ) = @_;

	my $slot = $slots[0];

	return {	
		$_->name => MO::Run::Method::Simple->new(
			body => sub {
				my ( $instance, @args ) = @_;

				if ( @args ) {
					return $slot->set_value( $instance, @args );
				} else {
					return $slot->get_value( $instance );
				}
			},
		),
	};
}

sub fields {
	my ( $self, $class ) = @_;

	return MO::Compile::Field::Simple->new(
		name      => $self->name,
		attribute => $self,
	);
}

__PACKAGE__;

__END__
