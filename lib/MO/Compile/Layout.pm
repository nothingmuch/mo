#!/usr/bin/perl

package MO::Compile::Layout;
use Moose::Role;

requires "create_instance_structure";

requires "fields";

requires "slot_for_field";

sub slots {
	my $self = shift;
	$self->slots_for_fields( $self->fields );
}

sub slots_for_fields {
	my ( $self, @fields ) = @_;
	map { $self->slot_for_field($_) } @fields;
}

sub initialize_instance_fields { # FIXME ugly implementation... use Tie::RefHash?
	my ( $self, $instance, %params ) = @_;

	my @fields;
	my @values;

	my $i = 0;
	foreach my $item ( @{ $params{fields} } ) {
		push @{ (\@fields, \@values)[$i++ % 2] }, $item;
	}

	my @slots = $self->slots_for_fields( @fields );

	$_->set_value( $instance, shift @values ) for @slots;
}

__PACKAGE__;

__END__
