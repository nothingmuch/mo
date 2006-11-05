#!/usr/bin/perl

package MO::Compile::Class;
use Moose::Role;

use MO::Compile::Role;

use MO::Util::Collection;
use MO::Util::Collection::Merge;
use MO::Util::Collection::Shadow;
use MO::Util::Collection::Shadow::Accessor;

use MO::Compile::Method::Simple;
use MO::Compile::Method::Private;
use MO::Compile::Method::Simple::Compiled;
use MO::Compile::Class::Method::Constructor;

use MO::Run::ResponderInterface::MethodTable;
use MO::Run::ResponderInterface::Multiplexed::ByCaller;
use MO::Run::ResponderInterface::Multiplexed::AttributeGrammar;

use MO::Run::Responder::Invocant;

with qw/
	MO::Compile::Abstract::Class
	MO::Compile::Origin
/;

requires "layout_class";

has roles => (
	isa => "ArrayRef",
	is  => "rw",
	auto_deref => 1,
	default    => sub { [] },
);

has "attribute_grammars" => (
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

	my $public  = $self->public_[% foo %]_interface(@args);
	my $private = $self->private_[% foo %]_interfaces(@args);
	my $ag      = $self->attribute_grammar_[% foo %]_interfaces(@args);

	return $self->_combine_interfaces(
		public             => $public,
		private            => $private,
		attribute_grammars => $ag,
	);
}

sub public_[% foo %]_interface {
	my ( $self, @args ) = @_;
	$self->MO::Compile::Abstract::Class::_[% foo %]_interface(@args);
}

sub private_[% foo %]_interfaces {
	my ( $self, @args ) = @_;
	$self->_private_methods_to_caller_interfaces(
		$self->all_private_[% foo %]_methods(@args),
	)
}

[% END %];
no tt;

sub attribute_grammar_class_interfaces {
	my ( $self, @args ) = @_;
	return;
}

sub attribute_grammar_instance_interfaces {
	my ( $self, @args ) = @_;

	if ( my @ag = $self->attribute_grammars ) {
		my %interfaces;

		foreach my $key (qw/child root parent/) {
			use Tie::RefHash;
			tie my %hash, 'Tie::RefHash';
			$interfaces{$key} = \%hash;
		}

		foreach my $ag_instance ( @ag ) {
			my $ag = $ag_instance->attribute_grammar;
			my $sub_interface = $self->attribute_grammar_interface( $ag_instance, @args );
			$interfaces{$_}{$ag} = $sub_interface->{$_} for qw/child root parent/;
		}

		return \%interfaces;
	} else {
		return;
	}
}

sub attribute_grammar_interface {
	my ( $self, $ag, @args ) = @_;
	$ag->interface( $self, @args );
}

sub _private_methods_to_caller_interfaces {
	my ( $self, @methods ) = @_;
	return unless @methods;

	use Tie::RefHash;
	tie my %interfaces, 'Tie::RefHash';

	foreach my $attached_private_method ( @methods ) {
		my $private_method = $attached_private_method->method;

		my @visible_from = @{ $private_method->visible_from };

		foreach my $visible ( @visible_from ) {
			my $collection = $interfaces{$visible} ||= MO::Util::Collection->new;

			# take apart the private method into normal a method, but keep it attached
			$collection->add( $self->filter_and_reattach( $attached_private_method, sub {
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
	my ( $public, $private, $attribute_grammars ) = @params{qw/public private attribute_grammars/};

	my $interface = $public;

	if ( $private ) {
		$interface = MO::Run::ResponderInterface::Multiplexed::ByCaller->new(
			fallback_interface    => $interface,
			per_caller_interfaces => $private,
		);
	}

	if ( $attribute_grammars ) {
		$interface = MO::Run::ResponderInterface::Multiplexed::AttributeGrammar->new(
			fallback_interface => $interface,
			%$attribute_grammars,
		);
	}

	return $interface;
}

sub layout {
	my $self = shift;
	$self->_build_layout( map { $self->_attr_fields($_) } $self->all_attributes);
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
	my ( $self, $target, $accessor, @args ) = @_;

	my $attaching_accessor = $self->attaching_collection_accessor( $accessor, @args );

	my $shadower = MO::Util::Collection::Shadow::Accessor->new(
		accessor => $attaching_accessor,
	);

	MO::Util::Collection::Shadow->new->shadow(
		MO::Util::Collection->new( $shadower->shadow( $self->class_precedence_list ) ),
		MO::Util::Collection->new( $self->merged_roles->get_all_using_role_shadowing( $target, $attaching_accessor ) ),
	)
}

sub get_all_using_mro {
	my ( $self, $target, $accessor, @args ) = @_;

	my $attaching_accessor = $self->attaching_collection_accessor( $accessor, @args );

	return (
		(map { $_->$attaching_accessor->items } reverse $self->class_precedence_list),
		$self->merged_roles->get_all_using_role_inheritence($target, $attaching_accessor),
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
	$self->get_all_using_mro_shadowing( $self, "instance_methods" );
}

sub all_regular_class_methods {
	my $self = shift;
	$self->get_all_using_mro_shadowing( $self, "class_methods" )
}

sub all_regular_private_instance_methods {
	my $self = shift;

	$self->_process_private_methods(
		$self->get_all_using_mro( $self, "private_instance_methods" ),
	);
}

sub all_regular_private_class_methods {
	my $self = shift;

	$self->_process_private_methods(
		$self->get_all_using_mro( $self, "private_class_methods" ),
	);
}

sub all_attributes_shadowed {
	my $self = shift;
	$self->get_all_using_mro_shadowing( $self, "attributes" );
}

sub all_attributes {
	my $self = shift;
	$self->get_all_using_mro( $self, "attributes" );
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
		$_->attached_item->isa("MO::Compile::Method::Private")
			? $_
			: $self->_inflate_private_method($_),
	} @methods;
}

sub _inflate_private_method {
	my ( $self, $method ) = @_;

	$self->filter_and_reattach($method, sub {
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

# this is a bit of a hack, it applies shadowing to the methods, not the attrs
sub all_attribute_instance_methods {
	my $self = shift;

	my $attaching_accessor = $self->attaching_collection_accessor("attributes");

	$self->get_all_using_mro_shadowing( $self, sub {
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
	my ( $self, $attached_attr ) = @_;

	my $attr   = $attached_attr->attached_item;
	my $origin = $attached_attr->origin;

	my @slots = $self->_attr_slots( $attached_attr );

	return $attr->compile(
		target => $self,
		origin => $origin,
		slots  => \@slots,
	);
}

sub _attr_slots {
	my ( $self, $attr ) = @_;

	$self->layout->slots_for_fields( $self->_attr_fields( $attr ) );
}

sub _attr_fields {
	my ( $self, $attr ) = @_;
	$attr->fields( $self );
}

sub constructor_method {
	my $self = shift;

	my $layout              = $self->layout;
	my @compiled_attributes = $self->all_compiled_attributes;
	my $instance_interface  = $self->instance_interface;

	return $self->attach_item(
		$self,
		MO::Compile::Class::Method::Constructor->new(
	   		name                => "create_instance",
			layout              => $layout,
			initializers        => \@compiled_attributes,
			responder_interface => $instance_interface,
		),
	);
}

__PACKAGE__;

__END__
