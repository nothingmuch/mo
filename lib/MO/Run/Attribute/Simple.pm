#!/usr/bin/perl

package MO::Run::Attribute::Simple;
use Moose;

has attribute => (
	isa => "MO::Compile::Attribute::Simple",
	is  => "ro",
	handles => [ qw/name/ ],
);

has class => (
	isa => "MO::Compile::Class::SI",
	is  => "ro",
);

has slots => (
	isa => "ArrayRef",
	is  => "ro",
	auto_deref => 1,
);

sub initialize {
	my ( $self, $instance, %params ) = @_;
	
	my $slot = ( $self->slots )[0];

	$slot->initialize( $instance ); # lazy accessors may skip this

	if ( exists $params{ $self->name } ) {
		$slot->set_value( $instance, $params{ $self->name } );
	};
}

sub methods {
	my $self = shift;

	my $slot = ( $self->slots )[0];

	return {	
		$_->name => MO::Run::Method::Simple->new(
			body => sub {
				my ( $instance, @args ) = @_;

				if ( @args ) {
					return $slot->set_value( $instance, @args );
				} else {
					return $slot->get_value( $instance );
				}
			},
		),
	};
}



__PACKAGE__;

__END__
