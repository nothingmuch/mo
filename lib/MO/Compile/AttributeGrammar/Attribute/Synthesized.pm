#!/usr/bin/perl

package MO::Compile::AttributeGrammar::Attribute::Synthesized;
use Moose;

use MO::Run::MethodDefinition::Simple;

use Scalar::Util qw/refaddr/;

has method => (
	does => "MO::Compile::Method",
	is   => "ro",
	required => 1,
	handles => [qw/name/],
);

sub compile {
	my ( $self, $target ) = @_;

	my $body = $self->method->definition->body; # FIXME $self->method->compile($target);
	my $name = $self->name;

	return MO::Run::MethodDefinition::Simple->new(
		body => sub {
			my $i = shift;
			my $obj = $i->invocant;

			my $table = $MO::Compile::AttributeGrammar::AG_VALUE_TABLE{ refaddr($obj) } ||= do {
				#$MO::Compile::AttributeGrammar::AG_INSTANCE->_seen( $i );
				{};
			};

			unless ( exists $table->{$name} ) {
				local $@;
				push @MO::Compile::AttributeGrammar::AG_STACK, $i;
				eval { $table->{$name} = [ wantarray ? $i->$body() : scalar($i->$body()) ] };
				pop @MO::Compile::AttributeGrammar::AG_STACK;

				if ( my $err = $@ ) {
					warn "$@";
					delete $table->{$name};
					die $err;
				}
			}

			return unless defined wantarray;

			my $array = $table->{$name} || return;
			return wantarray
				? @$array
				: $array->[0];
		},
	);
}

__PACKAGE__;

__END__
