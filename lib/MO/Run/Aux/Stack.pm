#!/usr/bin/perl

package MO::Run::Aux::Stack;
use Moose;

use MO::Run::Aux::Stack::Frame;

use Carp qw/croak/;

has _stack => (
	isa => "ArrayRef",
	is  => "ro",
	default => sub { [] },
);

sub BUILD {
	my ( $self, $params ) = @_;

	if ( my $items = $params->{items} ) {
		croak "items must be an array reference" unless (ref($items) || '') eq "ARRAY";
		$self->push($_) for @$items;
	}
}

sub items {
	my $self = shift;
	map { $_->item } $self->frames;
}

sub frames {
	my $self = shift;
	@{ $self->_stack };
}

sub tail {
	my $self = shift;

	local $@;
	eval { $self->get_item(0) };
}

sub get_item {
	my ( $self, @args ) = @_;
	$self->get_frame( @args )->item;
}

sub clear {
	my $self = shift;

	$_->_popped(1) for $self->frames;

	@{ $self->_stack } = ();
}

sub get_frame {
	my ( $self, $index ) = @_;
	$index ||= 0;

	return $self->_stack->[ -1 - $index ] || croak "No stack frame at index $index";
}

sub pop {
	my ( $self, $frame ) = @_;

	my $tail = $self->get_frame(0);

	if ( $frame ) {
		croak "Inconsistent stack pop" unless $tail && $tail == $frame;
	}

	pop @{ $self->_stack };

	$tail->_popped(1);

	return $tail->item;
}

sub push {
	my ( $self, $item, @params ) = @_;

	chomp( my $debug = do { local $Carp::CarpLevel = $Carp::CarpLevel + 2;; Carp::shortmess } );

	my $frame = MO::Run::Aux::Stack::Frame->new(
		item    => $item,
		stack   => $self,
		autopop => defined(wantarray),
		debug   => $debug,
		@params,
	);

	my $stack = $self->_stack;
	push @$stack, $frame;

	if ( $frame->autopop ) {
		require Scalar::Util;
		Scalar::Util::weaken($stack->[-1]);
	}

	return $frame;
}

sub dump {
	my $self = shift;

	join("\n  ", map { join "", grep { defined } $_->item, $_->debug } reverse $self->frames) . "\n";
}

__PACKAGE__;

__END__
