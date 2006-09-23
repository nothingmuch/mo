#!/usr/bin/perl

package MO::Compile::Composable::Symmetric;
use Moose::Role;

use MO::Util::Collection::Merge;
use MO::Util::Collection::Shadow;
use MO::Compile::Composable::Symmetric::Util::Merge;

sub get_all_using_symmetric_shadowing {
	my ( $self, $target, $parents, $accessor, @args ) = @_;

	MO::Util::Collection::Shadow->new->shadow(
		$self->$accessor( @args ),
		$self->get_symmetrically_merged_parent_collections( $target, $parents, $accessor, @args ),
	),
}

sub get_collection_using_symmetric_shadowing {
	my ( $self, @args ) = @_;
	MO::Util::Collection->new( $self->get_all_using_symmetric_shadowing(@args) );
}

sub get_symmetrically_merged_parent_collections {
	my ( $self, $target, $parents, $accessor, @args ) = @_;

	my @collections = map { $_->get_collection_using_symmetric_shadowing( $target, $parents, $accessor, @args ) } $self->$parents($target, @args);

	return MO::Util::Collection->new(
		MO::Compile::Composable::Symmetric::Util::Merge->new->merge( @collections )
	);
}

sub get_all_using_symmetric_inheritence {
	my ( $self, $target, $parents, $accessor, @args ) = @_;

	return (
		( map { $_->get_all_using_symmetric_inheritence( $target, $parents, $accessor, @args ) } $self->$parents($target, @args) ),
		$self->$accessor( @args )->items,
	);
}

__PACKAGE__;

__END__
