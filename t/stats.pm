#!/usr/bin/perl

package t::stats;

use strict;
use warnings;

my %statistics;

my %starts;

sub finish {
	my ( $class, @counters) = @_;

	my $t = times;

	@statistics{@counters} = map { $t - ($_||0) } @starts{@counters};
}

sub start {
	my ( $class, @counters ) = @_;
	@starts{@counters} = (scalar(times)) x @counters;
}

INIT {
	__PACKAGE__->finish("load");
}

END {
	__PACKAGE__->finish("total", grep { not exists $statistics{$_} } keys %starts);

	*MO::Run::Aux::MO_NATIVE_RUNTIME = sub { 0 } unless defined &MO::Run::Aux::MO_NATIVE_RUNTIME;

	if ( $ENV{MO_BENCH} and $? == 0 ) {
		require YAML::Syck;
		if ( my $file = $ENV{MO_BENCH_FILE} ) {

			my $struct = -e $file ? YAML::Syck::LoadFile($file) : {};

			my $saved = $struct->{ MO::Run::Aux::MO_NATIVE_RUNTIME() ? "native" : "interpreted" }{$0};

			if ( $ENV{MO_BENCH_AVG} ) {
				$saved = {} unless ref $saved eq 'HASH';
				my $count = delete $saved->{_count} || 0;

				my $total = $count + 1;

				foreach my $key ( keys %statistics ) {
					$saved->{$key} = ( $statistics{$key} + ( $count * ($saved->{$key} || $statistics{$key}) ) ) / $total;
				}

				$saved->{_count} = $total;
			} else {
				$saved = [] unless ref $saved eq 'ARRAY';
				push @$saved, \%statistics;

				if ( my $max = $ENV{MO_BENCH_MAX_SAVED} ) {
					shift @$saved while @$saved > $max;
				}
			}

			$struct->{ MO::Run::Aux::MO_NATIVE_RUNTIME() ? "native" : "interpreted" }{$0} = $saved;

			YAML::Syck::DumpFile($file, $struct);
		} else {
			print STDERR YAML::Syck::Dump({ elapsed_time => \%statistics });
		}
	}
}

__PACKAGE__;

__END__
