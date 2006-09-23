#!/usr/bin/perl

package MO::Compile::AttributeGrammar::Attribute::Inherited;
use Moose;

use MO::Run::MethodDefinition::Simple;

use Scalar::Util qw/refaddr/;

has name => (
	isa => "Str",
	is  => "ro",
	required => 1,
);

sub compile {
	my $self = shift;

	my $name = $self->name;

	return MO::Run::MethodDefinition::Simple->new(
		body => sub {
			my ( $i, @args ) = @_;
			my $obj = $i->invocant;

			my $table = $MO::Compile::AttributeGrammar::AG_VALUE_TABLE{ refaddr($obj) } ||= do {
				$MO::Compile::AttributeGrammar::AG_INSTANCE->_seen( $i );
				{};
			};

			if ( @args ) {
				$table->{$name} = ( @args == 1 ? [ $args[0] ] : \@args );				
			} else {
				unless ( exists $table->{$name} ) {

					my $parent = $MO::Compile::AttributeGrammar::AG_PARENT_TABLE{ refaddr($obj) } ||= do {
						warn "hacking parent, hardcoded to root, stack: @MO::Compile::AttributeGrammar::AG_STACK";
						$MO::Compile::AttributeGrammar::AG_STACK[0]; # FIXME
					};

					my $parent_interface = $parent->responder_interface->interface_for_ag_parent($MO::Compile::AttributeGrammar::AG); # FIXME use attached one in Inherited $self?

					my $thunk = $parent_interface->dispatch(
						$parent,
						MO::Run::Invocation::Method->new(
							name      => $name,
							arguments => [ $i ], # child
						),
					)->();
					
					unless ( exists $table->{$name} ) {
						die "Bestowing attribute $name in parent $parent did not set inherited attribute on $i";
					}
				}
			}

			return unless defined wantarray;

			return wantarray
				? @{ $table->{$name} }
				: $table->{$name}[0];
		},
	);
}

__PACKAGE__;

__END__