#!/usr/bin/perl

package MO::Util;

sub part_composition_failures {
	my ( @ok, @failures );

	foreach my $object ( @_ ) {
		my $is_failure = $object->can("is_composition_failure") && $object->is_composition_failure;

		push @{ $is_failure ? \@failures : \@ok }, $object;
	}

	return \( @ok, @failures );
}

__PACKAGE__;

__END__
