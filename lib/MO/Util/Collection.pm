#!/usr/bin/perl

package MO::Util::Collection;
use Moose;
use Moose::Util::TypeConstraints;

use Set::Object;
use Scalar::Util qw/refaddr/;
use Carp qw/croak/;

coerce "MO::Util::Collection" => (
	'ArrayRef'    => sub { __PACKAGE__->new(@{ $_[0] }) },
);

has by_obj => (
	isa => "Set::Object",
	is  => "rw",
	default => sub { Set::Object->new },
);

has by_name => (
	isa => "HashRef",
	is  => "rw",
	default => sub { return {} },
);

around new => sub {
	my $next = shift;
	my ( $class, @items ) = @_;
	my $self = $class->$next();
	$self->add( @items );
	return $self;
};

sub fmap {
	my ( $self, $f ) = @_;

	my $res = ( ref $self )->new;

	$res->add( map { $_->$f() } $self->items );

	return $res;
}

sub items {
	my $self = shift;
	$self->by_obj->members;
}

sub add {
	my ( $self, @items ) = @_;

	my %seen;
	croak "Can't insert @items: name conflict"
		if $self->includes_any( map { $_->name } @items )
		or scalar(@items) != scalar(grep { !$seen{$_->name}++ } @items);

	foreach my $item ( @items ) {
		$self->by_name->{ $item->name } = $item;
		$self->by_obj->insert( $item );
	}
}

sub includes_all {
	my ( $self, @items ) = @_;

	foreach my $item ( @items ) {
		return unless $self->includes($item);
	}

	return 1;
}

sub includes_any {
	my ( $self, @items ) = @_;

	foreach my $item ( @items ) {
		return 1 if $self->includes($item);
	}

	return;
}

sub includes {
	my ( $self, $item ) = @_;

	if ( ref $item ) {
		return $self->by_obj->includes($item);
	} else {
		return exists $self->by_name->{$item};
	}
}

sub remove {
	my ( $self, @items ) = @_;

	foreach my $item ( @items ) {
		if ( ref $item ) {
			delete $self->by_name->{ $item->name };
			$self->by_obj->remove( $item );
			return $item;
		} else {
			my $obj = delete $self->by_name->{ $item };
			$self->by_obj->remove( $obj );
			return $obj;
		}
	}
}

__PACKAGE__;

__END__
