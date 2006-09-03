#!/usr/bin/perl

package MO::Compile::Layout::Simple;
use Moose;

use MO::Compile::Slot::Simple;

use Tie::RefHash;

has class => (
	isa => "MO::Compile::Class::SI",
	is  => "ro",
	required => 1,
);

has fields => (
	isa => "ArrayRef",
	is  => "ro",
	auto_deref => 1,
	required   => 1,
);

has slots => (
	isa => "HashRef",
	is  => "ro",
	lazy    => 1,
	default => sub { $_[0]->_calculate_slots },
);

sub get_slots {
	my ( $self, $attribute ) = @_;
	@{ $self->slots->{$attribute} };
}	

sub _calculate_slots {
	my $self = shift;

	tie my %hash, 'Tie::RefHash';

	foreach my $field ( $self->fields ) {
		my $slot = MO::Compile::Slot::Simple->new( name => $field->name );
		push @{ $hash{ $field->attribute } ||= [] }, $slot;
	}

	return \%hash;
}

sub create_instance_structure {
	my ( $self, @params ) = @_;
	return { @params };
}

__PACKAGE__;

__END__
