#!/usr/bin/perl

package MO::Compile::Class;
use Moose::Role;

use MO::Compile::Role;

use MO::Util::Collection;
use MO::Util::Collection::Merge;
use MO::Util::Collection::Shadow;
use MO::Util::Collection::Shadow::Accessor;

use MO::Run::ResponderInterface::MethodTable;

use MO::Compile::Method::Simple;
use MO::Compile::Method::Private;
use MO::Run::MethodDefinition::Simple;

use MO::Run::ResponderInterface::Multiplexed::ByCaller;

use MO::Run::Responder::Invocant;

with "MO::Compile::Abstract::Class";

requires "layout_class";

has roles => (
	isa => "ArrayRef",
	is  => "rw",
	auto_deref => 1,
	default    => sub { [] },
);

has attributes => (
	isa => "MO::Util::Collection",
	is  => "rw",
	coerce  => 1,
	default => sub { MO::Util::Collection->new },
);

has instance_methods => (
	isa => "MO::Util::Collection",
	is  => "rw",
	coerce  => 1,
	default => sub { MO::Util::Collection->new },
);

has "private_instance_methods" => ( # submethods
	isa => "MO::Util::Collection",
	is  => "rw",
	coerce  => 1,
	default => sub { MO::Util::Collection->new },
);

has class_methods => (
	isa => "MO::Util::Collection",
	is  => "rw",
	coerce  => 1,
	default => sub { MO::Util::Collection->new },
);

has "private_class_methods" => ( # submethods
	isa => "MO::Util::Collection",
	is  => "rw",
	coerce  => 1,
	default => sub { MO::Util::Collection->new },
);

use tt;
[% FOR foo IN ["instance","class"] %]
sub [% foo %]_interface {
	my ( $self, @args ) = @_;

	my $public = $self->public_[% foo %]_interface(@args);
	my $private = $self->private_[% foo %]_interfaces(@args);

	if ( $private and scalar keys %$private ) {
		$self->_combine_interfaces(
			public  => $public,
			private => $private,
		);
	} else {
		return $public;
	}
}

sub public_[% foo %]_interface {
	my ( $self, @args ) = @_;
	$self->MO::Compile::Abstract::Class::_[% foo %]_interface(@args);
}

sub private_[% foo %]_interfaces {
	my ( $self, @args ) = @_;
	$self->_private_methods_to_caller_interfaces($self->all_private_[% foo %]_methods(@args));
}
[% END %]
no tt;

sub _private_methods_to_caller_interfaces {
	my ( $self, @methods ) = @_;

	use Tie::RefHash;
	tie my %interfaces, 'Tie::RefHash';

	foreach my $attached_private_method ( @methods ) {
		my $private_method = $attached_private_method->method;

		my @visible_from = @{ $private_method->visible_from };

		foreach my $visible ( @visible_from ) {
			my $collection = $interfaces{$visible} ||= MO::Util::Collection->new;

			# take apart the private method into normal a method, but keep it attached
			$collection->add( $self->_reattach( $attached_private_method, sub {
				my ( $private_method, $attached ) = @_;
				return $private_method->method;
			}) );
		}
	}

	foreach my $i ( values %interfaces ) {
		$i = $self->_interface_from_methods( $i->items );
	}

	return \%interfaces;
}

sub _combine_interfaces {
	my ( $self, %params ) = @_;
	my ( $public, $private ) = @params{qw/public private/};

	MO::Run::ResponderInterface::Multiplexed::ByCaller->new(
		fallback_interface    => $public,
		per_caller_interfaces => $private,
	);
}

sub layout {
	my $self = shift;
	$self->_build_layout( map { $_->fields($self) } $self->all_attributes);
}

sub _build_layout {
	my ( $self, @fields ) = @_;

	$self->layout_class->new(
		class  => $self,
		fields => \@fields,
	);
}

sub merged_roles {
	my $self = shift;

	MO::Compile::Role->new(
		roles => [ $self->roles ],
	);
}

sub get_all_using_mro_shadowing {
	my ( $self, $accessor, @args ) = @_;

	my $attaching_accessor = $self->_attaching_accessor( $accessor, @args );

	my $shadower = MO::Util::Collection::Shadow::Accessor->new(
		accessor => $attaching_accessor,
	);

	MO::Util::Collection::Shadow->new->shadow(
		MO::Util::Collection->new( $shadower->shadow( $self->class_precedence_list ) ),
		MO::Util::Collection->new( $self->merged_roles->get_all_using_role_shadowing( $attaching_accessor ) ),
	)
}

sub get_all_using_mro {
	my ( $self, $accessor, @args ) = @_;

	my $attaching_accessor = $self->_attaching_accessor( $accessor, @args );

	return (
		(map { $_->$attaching_accessor->items } reverse $self->class_precedence_list),
		$self->merged_roles->get_all_using_role_inheritence($attaching_accessor),
	);
}

sub _attaching_accessor {
	my ( $self, $accessor, @args ) = @_;

	return sub {
		my $class_or_role = shift;
		$self->_attach_collection(
			$class_or_role,
			$class_or_role->$accessor(@args)
		);
	};
}

sub _attach_collection {
	my ( $self, $origin, $collection ) = @_;

	MO::Util::Collection->new(
		map {
			$_->can("attach")
				? $_->attach($origin)
		   		:  $_
		} $collection->items
	);
}

sub all_instance_methods {
	my $self = shift;

	return (
		$self->all_attribute_instance_methods,
		$self->all_regular_instance_methods,
	);
}

sub all_class_methods {
	my $self = shift;
	return (
		$self->all_regular_class_methods,
		$self->special_class_methods,
	);
}

sub all_private_instance_methods {
	my $self = shift;

	return $self->_merge_private_methods(
		$self->all_attribute_private_instance_methods,
		$self->all_regular_private_instance_methods,
	);
}

sub all_private_class_methods {
	my $self = shift;

	return $self->_merge_private_methods(
		$self->all_regular_private_class_methods,
		$self->special_private_class_methods,
	);
}

sub all_regular_instance_methods {
	my $self = shift;
	$self->get_all_using_mro_shadowing( "instance_methods" );
}

sub all_regular_class_methods {
	my $self = shift;
	$self->get_all_using_mro_shadowing( "class_methods" )
}

sub all_regular_private_instance_methods {
	my $self = shift;

	$self->_process_private_methods(
		$self->get_all_using_mro( "private_instance_methods" ),
	);
}

sub all_regular_private_class_methods {
	my $self = shift;

	$self->_process_private_methods(
		$self->get_all_using_mro( "private_class_methods" ),
	);
}

sub all_attributes_shadowed {
	my $self = shift;
	$self->get_all_using_mro_shadowing( "attributes" );
}

sub all_attributes {
	my $self = shift;
	$self->get_all_using_mro( "attributes" );
}

sub special_class_methods {
	my $self = shift;
	return (
		$self->constructor_method,
	);
}

sub special_private_class_methods {
	my $self = shift;
	return ();
}

sub _process_private_methods {
	my ( $self, @pre_methods ) = @_;

	# all are attached, private, not mixed
	my @methods = $self->_inflate_private_methods(@pre_methods);

	$self->_merge_private_methods( @methods );
}

# make private methods who don't have visible_from specified inflate into submethods
sub _inflate_private_methods {
	my ( $self, @methods ) = @_;

	map {
		$_->method->isa("MO::Compile::Method::Private")
			? $_
			: $self->_inflate_private_method($_),
	} @methods;
}

sub _inflate_private_method {
	my ( $self, $method ) = @_;

	$self->_reattach($method, sub {
		my ( $method, $attached ) = @_;
		MO::Compile::Method::Private->new(
			method       => $method,
			visible_from => [ $attached->origin ],
		);
	});
}

sub _merge_private_methods {
	my ( $self, @methods ) = @_;
	@methods;
}

sub _reattach {
	my ( $self, $attached, $futz ) = @_;

	(ref $attached)->new(
		method => $futz->( $attached->attached_item, $attached ),
		origin => $attached->origin,
	);
}

# this is a bit of a hack, it applies shadowing to the methods, not the attrs
sub all_attribute_instance_methods {
	my $self = shift;

	my $attaching_accessor = $self->_attaching_accessor("attributes");

	$self->get_all_using_mro_shadowing( sub {
		my $ancestor = shift;

		my @attrs = $ancestor->$attaching_accessor->items;
		my @method_collections = map { $self->methods_of_attribute($_) } @attrs;
	
		# per ancestor all the accessors are merged symmetrically	
		MO::Util::Collection->new( MO::Util::Collection::Merge->new->merge( @method_collections ) );
	});
}

sub all_attribute_private_instance_methods {
	my $self = shift;

	my @attrs = $self->all_attributes;

	$self->_process_private_methods(
		map { $self->private_methods_of_attribute($_)->items } @attrs,
	);
}

sub all_compiled_attributes {
	my $self = shift;
	map { $self->compile_attribute($_) } $self->all_attributes;
}

sub methods_of_attribute {
	my ( $self, $attr ) = @_;

	MO::Util::Collection->new(
		$self->compile_attribute( $attr )->methods,
	);
}

sub private_methods_of_attribute {
	my ( $self, $attr ) = @_;

	MO::Util::Collection->new(
		$self->compile_attribute( $attr )->private_methods,
	);
}


sub compile_attribute {
	my ( $self, $attr ) = @_;

	my @slots = $self->_attr_slots( $attr );

	return $attr->compile(
		class => $self,
		slots => \@slots,
	);
}

sub _attr_slots {
	my ( $self, $the_attr ) = @_;

	my @fields;
	my ( $from, $to );
	foreach my $attached_attr ( $self->all_attributes ) {
		if ( $attached_attr->attribute == $the_attr->attribute ) {
			$from = scalar @fields;
			push @fields, $attached_attr->fields($self);
			$to = $#fields;
		} else {
			push @fields, $attached_attr->fields($self);
		}
	}

	die "Can't compile slots for attribute " . $the_attr->name . ": it's not in the list of all attributes"
		unless defined $from and defined $to;

	( $self->layout->slots )[ $from .. $to ];
}

sub constructor_method {
	my $self = shift;

	my $layout              = $self->layout;
	my @compiled_attributes = $self->all_compiled_attributes;
	my $instance_interface  = $self->instance_interface;

	return MO::Compile::Method::Simple->new(
		name       => "create_instance",
		definition => MO::Run::MethodDefinition::Simple->new(
			body => sub {
				my ( $class, @params ) = @_;

				my $object = $layout->create_instance_structure;

				$_->initialize( $object, @params )
				for @compiled_attributes;

				MO::Run::Responder::Invocant->new(
					object              => $object,
					responder_interface => $instance_interface,
				);
			}
		),
	);
}

__PACKAGE__;

__END__
