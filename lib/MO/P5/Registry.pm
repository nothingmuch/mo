#!/usr/bin/perl

package MO::P5::Registry;
use Moose;

use Class::MOP::Package;
use Tie::RefHash;
use Carp qw/croak/;

has classes => (
	isa => "HashRef",
	is  => "rw",
	default => sub { return {} }
);

has classes_inverted => (
	isa => "HashRef",
	is  => "rw",
	default => sub { tie my %h, "Tie::RefHash"; \%h },
);

has pmc_classes => (
	isa => "HashRef",
	is  => "rw",
	default => sub { return {} },
);

has packages => (
	isa => "HashRef",
	is  => "rw",
	default => sub { return {} }
);

has prefix => (
	isa => "Str",
	is  => "rw",
	default => "",
);

has emitter => (
	isa => "Object",
	is  => "rw",
	lazy    => 1,
	default => sub { require MO::Emit::P5; MO::Emit::P5->new },
);

has emitted => (
	isa => "HashRef",
	is  => "rw",
	default => sub { tie my %h, "Tie::RefHash"; \%h },
);

sub autovivify_class {
	my ( $self, $class, $namegen ) = @_;

	unless ( $self->class_is_emitted($class) ) {
		unless ( $self->class_is_registered($class) ) {
			$namegen ||= do { require MO::Run::Aux; \&MO::Run::Aux::_generate_package_name };
			$self->register_class( my $pkg = $namegen->($class), $class );
		}

		$self->emit_all_classes();
	}
	
	return $self->package_of_class($class);
}

sub class_is_registered {
	my ( $self, $class ) = @_;	
	exists $self->classes_inverted->{$class};
}

sub package_of_class {
	my ( $self, $class ) = @_;
	$self->classes_inverted->{$class};
}

sub class_of_package {
	my ( $self, $pkg ) = @_;
	$self->load_pmc_meta($pkg);
	$self->classes->{$pkg};
}

sub class_is_emitted {
	my ( $self, $class ) = @_;
	$self->emitted->{$class};
}

sub emit_all_classes {
	my ( $self, @params ) = @_;

	foreach my $pkg ( keys %{ $self->packages } ) {
		my $class = $self->classes->{$pkg};
		next if $self->pmc_classes->{$pkg} or $self->emitted->{$class}++;

		my $pkg_obj = $self->packages->{$pkg};

		# remove the AUTOLOAD trampoline
		$pkg_obj->remove_package_symbol('&AUTOLOAD');

		$self->emitter->emit_class(
			@params,
			'package' => $pkg_obj,
			class     => $class,
			registry  => $self,
		);
	}
}

sub register_class {
	my ( $self, $package, $class, @params ) = @_;

	if ( ref $package ) {
		unshift @params, $class if defined $class;
		$class = $package;
		$package = caller();
	}

	die "Package $package is already in use" if exists $self->classes->{package};
	die "Class $class is already registered as " . $self->classes_inverted->{$class} if exists $self->classes_inverted->{$class};

	my $pkg_obj = $self->packages->{$package} = $self->create_package_object( $package );
	$self->classes_inverted->{$class} = $package;
	$self->classes->{$package} = $class;

	$pkg_obj->add_package_symbol( '&AUTOLOAD' => sub {
		# let the package spring into existence
		# this will also remove our AUTOLOAD
		$self->emit_all_classes();

		# resume native dispatch
		my ( $method ) = ( our $AUTOLOAD =~ /([^:]+)$/ );
		my $code = do { no warnings; UNIVERSAL::can( $_[0], $method ) };
		goto $code;
	});
}

sub register_pmc_class {
	my ( $self, $pkg ) = @_;

	$self->pmc_classes->{$pkg}++;
}

sub load_pmc_meta {
	my ( $self, $pkg ) = @_;
	return if $self->packages->{$pkg};
	return unless $self->pmc_classes->{$pkg};

	(my $file = "${pkg}.pm") =~ s{::}{/}g;

	eval "#line 1 $INC{$file}\n" . do { local $/; open my $fh, "<", $INC{$file}; <$fh> }; # FIXME YUCKYUKCYUCKCKCKCKC
}

sub create_package_object {
	my ( $self, $package ) = @_;
	Class::MOP::Package->initialize( $package );
}

__PACKAGE__;

__END__
