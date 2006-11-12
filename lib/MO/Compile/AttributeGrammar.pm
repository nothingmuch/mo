#!/usr/bin/perl

package MO::Compile::AttributeGrammar;
use Moose;

with qw/MO::Compile::Origin/;

use MO::Run::ResponderInterface::Filtered;
use MO::Run::Responder::Invocant;
use MO::Compile::Method::Simple::Compiled;
use MO::Util::Collection;
use MO::Run::Aux;

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
		origin => $self,
		methods => {
			create_instance => MO::Compile::Method::Simple::Compiled->new(
				body => sub {
					my ( $ag_inv, %params ) = @_;

					my $ag = MO::Run::Aux::unbox_value( $ag_inv ),

					my $root = $params{root} || die "Attribute grammars need a root object";

					my $root_interface = $root->responder_interface->interface_for_ag_root( $ag );

					my $ag_instance = {
						root    => $root,
						values  => {},
						parents => {},
						ag      => $ag,
					};

					return MO::Run::Aux::box(
						$ag_instance,
						MO::Run::ResponderInterface::Filtered->new(
							responder_filter => sub {
								my ( $responder, $invocation, $responder_interface ) = @_;
								MO::Run::Aux::unbox_value($responder)->{root};
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
