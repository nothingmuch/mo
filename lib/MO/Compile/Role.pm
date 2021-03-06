#!/usr/bin/perl

package MO::Compile::Role;
use Moose;

with qw/
	MO::Compile::Abstract::Role
	MO::Compile::Origin
	MO::Compile::Composable::Symmetric
/;

use MO::Util::Collection;


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

sub get_parent_roles {
	my ( $self, $target, @args ) = @_;
	$self->roles;
}

sub get_all_using_role_shadowing {
	my ( $self, $target, $accessor, @args ) = @_;
	$self->get_all_using_symmetric_shadowing( $target, "get_parent_roles", $accessor, @args );
}

sub get_all_using_role_inheritence {
	my ( $self, $target, $accessor, @args ) = @_;
	$self->get_all_using_symmetric_inheritence( $target, "get_parent_roles", $accessor, @args );
}

# FIXME
# these should go away?

sub all_regular_instance_methods {
	my $self = shift;
	$self->get_all_using_role_shadowing( $self, "instance_methods" );
}

sub all_regular_class_methods {
	my $self = shift;
	$self->get_all_using_role_shadowing( $self, "class_methods" )
}

sub all_attributes {
	my $self = shift;
	$self->get_all_using_role_inheritence( $self, "attributes" );
}

__PACKAGE__;

__END__
