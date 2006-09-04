#!/usr/bin/perl

package MO::Compile::Class::MI::MRO::C3;
use Moose;

with "MO::Compile::Class::MI::MRO";

use Algorithm::C3 ();

sub linearize {
	my ( $self, $class ) = @_;
	Algorithm::C3::merge( $class, "superclasses" );
}

__PACKAGE__;

__END__
