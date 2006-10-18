#!/usr/bin/perl

package MO::Compile::AttributeGrammar;
use Moose;

use MO::Run::ResponderInterface::Filtered;
use MO::Run::Responder::Invocant;
use MO::Run::MethodDefinition::Simple;
use MO::Util::Collection;

has ancestors => (
	isa => "ArrayRef",
	is  => "ro",
	auto_deref => 1,
);

has root_attributes => (
	isa => "MO::Util::Collection",
	is  => "rw",
	coerce  => 1,
	default => sub { MO::Util::Collection->new },
);

our $AG;
our $AG_ROOT;
our %AG_VALUE_TABLE;
our %AG_PARENT_TABLE;
our @AG_STACK;

sub _seen {
	my ( $self, $instance ) = @_;
	# iterate attributes, add implicit parents
}

sub responder_interface {
	my $self = shift;
	MO::Run::ResponderInterface::MethodTable->new(
		methods => {
			create_instance => MO::Run::MethodDefinition::Simple->new(
				body => sub {
					my ( $ag_inv, %params ) = @_;

					my $ag = $ag_inv->invocant,

					my $root = $params{root} || die "Attribute grammars need a root object";

					my $root_interface = $root->responder_interface->interface_for_ag_root( $ag );

					my $ag_instance = {
						root    => $root,
						values  => {},
						parents => {},
						ag      => $ag,
					};

					return MO::Run::Responder::Invocant->new(
						invocant => $ag_instance,
						responder_interface => MO::Run::ResponderInterface::Filtered->new(
							responder_filter => sub {
								my ( $responder, $invocation, $responder_interface ) = @_;
								$responder->invocant->{root};
							},
							around_filter    => sub {
								my ( $thunk, $responder, $invocation, $responder_interface ) = @_;
								return sub {
									local $AG              = $ag;
									local $AG_ROOT         = $root;
									local *AG_VALUE_TABLE  = $ag_instance->{values};
									local *AG_PARENT_TABLE = $ag_instance->{parents};
									local *AG_STACK        = [];
									$thunk->(@_);
								};
							},
							responder_interface => $root_interface,
						),
					);
				},
			),
		},
	);
}

__PACKAGE__;

__END__
