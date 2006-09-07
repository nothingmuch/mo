#!/usr/bin/perl

package MO::Compile::Role;
use Moose;

with "MO::Compile::Abstract::Role";

use MO::Util::Collection;
use MO::Util::Collection::Merge;
use MO::Util::Collection::Shadow;
use MO::Compile::Role::Util::Merge;

sub roles {}
has roles => (
	isa => "ArrayRef",
	is  => "rw",
	auto_deref => 1,
	default    => sub { [] },
);

has attributes => (
	isa => "MO::Util::Collection",
	is  => "rw",
	coerce  => 1,
	default => sub { MO::Util::Collection->new },
);

has instance_methods => (
	isa => "MO::Util::Collection",
	is  => "rw",
	coerce  => 1,
	default => sub { MO::Util::Collection->new },
);

has "private_instance_methods" => ( # submethods
	isa => "MO::Util::Collection",
	is  => "rw",
	coerce  => 1,
	default => sub { MO::Util::Collection->new },
);

has class_methods => (
	isa => "MO::Util::Collection",
	is  => "rw",
	coerce  => 1,
	default => sub { MO::Util::Collection->new },
);

has "private_class_methods" => ( # submethods
	isa => "MO::Util::Collection",
	is  => "rw",
	coerce  => 1,
	default => sub { MO::Util::Collection->new },
);

sub get_all_using_role_shadowing {
	my ( $self, $accessor, @args ) = @_;

	MO::Util::Collection::Shadow->new->shadow(
		$self->$accessor( @args ),
		$self->get_merged_parent_collections($accessor, @args),
	),
}

sub get_collection_using_role_shadowing {
	my ( $self, @args ) = @_;
	MO::Util::Collection->new( $self->get_all_using_role_shadowing( @args ) );
}

sub get_merged_parent_collections {
	my ( $self, $accessor, @args ) = @_;

	my @collections = map { $_->get_collection_using_role_shadowing($accessor, @args) } $self->roles;
	
	return MO::Util::Collection->new(
		MO::Compile::Role::Util::Merge->new->merge( @collections )
	);
}

sub get_all_using_role_inheritence {
	my ( $self, $accessor, @args ) = @_;

	return (
		( map { $_->get_all_using_role_inheritence($accessor, @args) } $self->roles ),
		$self->$accessor( @args )->items,
	);
}

sub all_regular_instance_methods {
	my $self = shift;
	$self->get_all_using_role_shadowing( "instance_methods" );
}

sub all_regular_class_methods {
	my $self = shift;
	$self->get_all_using_role_shadowing( "class_methods" )
}

sub all_attributes {
	my $self = shift;
	$self->get_all_using_role_inheritence( "attributes" );
}

__PACKAGE__;

__END__
