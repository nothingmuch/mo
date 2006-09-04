#!/usr/bin/perl

package MO::Compile::Class::MI;
use Moose;

use MO::Compile::Class::Layout::Hash;

with "MO::Compile::Class";

has mro => (
	does => "MO::Compile::Class::MI::MRO",
	is   => "rw",
	default => sub {
		require MO::Compile::Class::MI::MRO::C3;
		MO::Compile::Class::MI::MRO::C3->new;
	},
);

sub superclasses {} # keep role composition happy
has superclasses => (
	isa  => "ArrayRef",
	is   => "rw",
	auto_deref => 1,
	default => sub { return [] },
);

sub layout_class { }
has layout_class => (
	isa => "Str",
	is  => "rw",
	default => "MO::Compile::Class::Layout::Hash", # FIXME
);

sub class_precedence_list {
	my $self = shift;
	$self->mro->linearize($self);
}

__PACKAGE__;

__END__
