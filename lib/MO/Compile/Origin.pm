#!/usr/bin/perl

package MO::Compile::Origin;
use Moose::Role;

sub attaching_collection_accessor {
	my ( $self, $accessor, @curried_args ) = @_;
	$self->_attaching_accessor( "attach_collection", $accessor, @curried_args );
}

sub attaching_item_accessor {
	my ( $self, $accessor, @curried_args ) = @_;
	$self->_attaching_accessor( "attach_item", $accessor, @curried_args );
}

sub _attaching_accessor {
	my ( $self, $attacher, $accessor, @curried_args ) = @_;

	return sub {
		my ( $origin, @args ) = @_;
		$self->$attacher(
			$origin,
			$origin->$accessor(@curried_args, @args)
		);
	};
}

sub attach_collection {
	my ( $self, $origin, $collection ) = @_;
	$collection->fmap(sub { $self->attach_item( $origin, shift ) });
}

sub detach_collection {
	my ( $self, $collection ) = @_;
	$collection->fmap(sub { $self->detach_item( shift ) });
}

sub attach_item {
	my ( $self, $origin, $item ) = @_;

	if ( $item->does("MO::Compile::Attached") ) {
		return $item;
	} else {
		$item->attach( $origin );
	}
}

sub force_attach_item {
	my ( $self, $origin, $item ) = @_;

	$self->attached_item( $self->detach_item( $item ) );
}

sub detach_item {
	my ( $self, $item ) = @_;

	if ( $item->does("MO::Compile::Attached") ) {
		$item->attached_item;
	} else {
		$item;
	}
}

sub filter_and_reattach {
	my ( $self, $attached, $mapping ) = @_;

	my $filtered = $mapping->( $attached->attached_item, $attached );

	$self->attach_item( $attached->origin, $filtered );
}

__PACKAGE__;

__END__
