#!/usr/bin/perl

package MO::P5::Registry;
use Moose;

use Class::MOP::Package;
use Tie::RefHash;
use Carp qw/croak/;

foreach my $field (qw/classes roles/) {
	has $field => (
		isa => "HashRef",
		is  => "rw",
		default => sub { return {} }
	);

	has "${field}_inverted" => (
		isa => "HashRef",
		is  => "rw",
		default => sub { tie my %h, "Tie::RefHash"; \%h },
	);
}

has pmc_packages => (
	isa => "HashRef",
	is  => "rw",
	default => sub { return {} },
);

has package_objects => (
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

sub role_is_registered {
	my ( $self, $class ) = @_;
	exists $self->roles_inverted->{$class};
}

sub class_is_registered {
	my ( $self, $class ) = @_;
	exists $self->classes_inverted->{$class};
}

sub package_of_class {
	my ( $self, $class ) = @_;
	$self->classes_inverted->{$class};
}

sub load_package {
	my ( $self, $package ) = @_;
	(my $file = "${package}.pm") =~ s{::}{/}g;
	local $@;
	eval { require $file };
}

sub package_to_meta {
	my ( $self, $pkg ) = @_;
	$self->load_package($pkg);
	$self->load_pmc_meta($pkg);
	$self->classes($pkg) || $self->roles($pkg) || die "No meta for package $pkg";
}

sub role_of_package {
	my ( $self, $pkg ) = @_;
	$self->load_package($pkg);
	$self->load_pmc_meta($pkg);
	$self->roles->{$pkg} || die "No meta role for package $pkg";
}

sub class_of_package {
	my ( $self, $pkg ) = @_;
	$self->load_package($pkg);
	$self->load_pmc_meta($pkg);
	$self->classes->{$pkg} || die "No meta class for package $pkg";
}

sub class_is_emitted {
	my ( $self, $class ) = @_;
	$self->emitted->{$class};
}

sub emit_all_classes {
	my ( $self, @params ) = @_;

	foreach my $pkg ( keys %{ $self->package_objects } ) {
		my $class = $self->classes->{$pkg} || next;
		next if $self->pmc_packages->{$pkg} or $self->emitted->{$class}++;

		my $pkg_obj = $self->package_objects->{$pkg};

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

sub register_role {
	my ( $self, $package, $role, @params ) = @_;

	if ( ref $package ) {
		unshift @params, $role if defined $role;
		$role = $package;
		$package = caller();
	}

	die "Package $package is already in use" if exists $self->package_objects->{$package};
	die "Role $role is already registered as " . $self->roles_inverted->{$role} if exists $self->roles_inverted->{$role};

	my $pkg_obj = $self->package_objects->{$package} = $self->create_package_object( $package );
	$self->roles_inverted->{$role} = $package;
	$self->roles->{$package} = $role;
}

sub register_class {
	my ( $self, $package, $class, @params ) = @_;

	if ( ref $package ) {
		unshift @params, $class if defined $class;
		$class = $package;
		$package = caller();
	}

	die "Package $package is already in use" if exists $self->package_objects->{$package};
	die "Class $class is already registered as " . $self->classes_inverted->{$class} if exists $self->classes_inverted->{$class};

	my $pkg_obj = $self->package_objects->{$package} = $self->create_package_object( $package );
	$self->classes_inverted->{$class} = $package;
	$self->classes->{$package} = $class;

	unless ( $self->pmc_packages->{$package} ) {
		$pkg_obj->add_package_symbol( '&AUTOLOAD' => sub {
			# let the package spring into existence
			# this will also remove our AUTOLOAD
			$self->emit_all_classes();

			# resume native dispatch
			my ( $method ) = ( our $AUTOLOAD =~ /([^:]+)$/ );

			return if $method eq "DESTROY"; # if there is no destroy it isn't an error

			my $code = do { no warnings; UNIVERSAL::can( $_[0], $method ) }
				or die qq{Can't locate object method "$method" via package "} . (ref($_[0]) || $_[0]) . '"';

			goto $code;
		});
	}
}

sub register_pmc_class {
	my ( $self, $pkg ) = @_;

	$self->pmc_packages->{$pkg}++;
}

sub load_pmc_meta {
	my ( $self, $pkg ) = @_;
	return if $self->package_objects->{$pkg};
	return unless $self->pmc_packages->{$pkg};

	(my $file = "${pkg}.pm") =~ s{::}{/}g;

=begin comment
	# this is more correct but doesn't work

	my @old_inc = @INC;
	local @INC = sub {
		my (undef, $file) = @_;

		warn "really really loading: $file";

		my @lines = ( "# line 1 $file\n", do { local @ARGV = $file; <> } );

		@INC = @old_inc; # for subsequent requires

		return sub {
			$_ = shift @lines;
			return length( $_ || '');
		};
	};

	warn "going to require $file";

	require $INC{$file};
=cut

	# FIXME Sub::Uplevel?
	eval "#line 1 $INC{$file}\n" . do { local (@ARGV, $/) = $INC{$file}; <> }; # FIXME YUCKYUKCYUCKCKCKCKC
	die $@ if $@;
}

sub create_package_object {
	my ( $self, $package ) = @_;
	$package = "MO::bootstrap::$package" if $package =~ /^MO::/;
	Class::MOP::Package->initialize( $self->prefix . $package );
}

__PACKAGE__;

__END__
