#!/usr/bin/perl

package MO::Compile::Class::SI;
use Moose;

with "MO::Compile::Class";

use MO::Compile::Class::SI::Layout::Hash;

has superclass => (
	isa => "MO::Compile::Class::SI",
	is  => "rw",
);

sub layout_class { }
has layout_class => (
	isa => "Str",
	is  => "rw",
	default => "MO::Compile::Class::SI::Layout::Hash",
);

sub superclasses {
	my ( $self, @args ) = @_;
	$self->superclass(@args);
}

sub class_precedence_list {
	my $self = shift;
	
	if ( my $superclass = $self->superclass ) {
		return ( $self, $superclass->class_precedence_list );
	} else {
		return $self;
	}
}

__PACKAGE__;

__END__
