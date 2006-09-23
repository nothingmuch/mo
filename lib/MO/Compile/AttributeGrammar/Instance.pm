#!/usr/bin/perl

package MO::Compile::AttributeGrammar::Instance;
use Moose;

extends "MO::Compile::Role";

has inherited_attributes => (
	isa => "MO::Util::Collection",
	is  => "rw",
	coerce  => 1,
	default => sub { MO::Util::Collection->new },
);

has synthesized_attributes => (
	isa => "MO::Util::Collection",
	is  => "rw",
	coerce  => 1,
	default => sub { MO::Util::Collection->new },
);

has bestowed_attributes => (
	isa => "MO::Util::Collection",
	is  => "rw",
	coerce  => 1,
	default => sub { MO::Util::Collection->new },
);

sub get_parent_ag_instances {
	my ( $self, $class ) = @_;

	my @ancestors = $self->attribute_grammar->ancestors;

	my @all_other_ag_instances = $class->attribute_grammars;

	my @parent_ag_instances;
	instance: foreach my $ag_instance ( @all_other_ag_instances ) {
		foreach my $ancestor ( @ancestors ) {
			if ( $ag_instance->attribute_grammar == $ancestor ) {
				push @parent_ag_instances, $ag_instance;
				next instance;
			}
		}
	}

	return @parent_ag_instances;
}

sub interface {
	my ( $self, $target, @args ) = @_;

	my $synthesized = MO::Util::Collection->new( $self->get_all_using_symmetric_shadowing( $target, "get_parent_ag_instances", "synthesized_attributes", @args ) );
	my $inherited   = MO::Util::Collection->new( $self->get_all_using_symmetric_shadowing( $target, "get_parent_ag_instances", "inherited_attributes",   @args ) );
	my $root        = $self->attribute_grammar->root_attributes;

	# The interfaces for each behavior a class with an AG instance can perform
	my %interfaces = (
		child  => [ MO::Util::Collection::Merge->new->merge( $synthesized, $inherited ) ],
		root   => [ MO::Util::Collection::Shadow->new->shadow( $root, $synthesized ) ],
		parent => [ $self->get_all_using_symmetric_shadowing( $target, "get_parent_ag_instances", "bestowed_attributes", @args ) ],
	);

	for ( values %interfaces ) {
		$_ = MO::Run::ResponderInterface::MethodTable->new(
			methods => { map { $_->name => $_->compile($target) } @$_ },
		);
	}

	return \%interfaces;
}

has attribute_grammar => (
	isa => "MO::Compile::AttributeGrammar",
	is  => "ro",
	required => 1,
);

__PACKAGE__;

__END__
