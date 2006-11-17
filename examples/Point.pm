#!/usr/bin/perl

package Point;

use strict;
use warnings;

use MO::Run::Aux;

BEGIN { $MO::Run::Aux::MO_NATIVE_RUNTIME = 1 }

use MO::Compile::Class::MI;
use MO::Compile::Attribute::Simple;
use MO::Compile::Method::Simple;

MO::Run::Aux::registry()->register_class(
	MO::Compile::Class::MI->new(
		attributes => [
			MO::Compile::Attribute::Simple->new(
				name => "x",
			),
			MO::Compile::Attribute::Simple->new(
				name => "y",
			),
		],
		instance_methods => [
			MO::Compile::Method::Simple->new(
				name => "distance",
				definition => sub {
					my ( $self, $other ) = @_;
					sqrt( ( abs( $self->x - $other->x ) ** 2 ) + ( abs( $self->y - $other->y ) ** 2 ) );
				},
			),
		],
	)
);

####

MO::Run::Aux::registry()->emit_all_classes();

use Generate::PMC::File;
use Data::Dump::Streamer ();

{
	my $pkg = __PACKAGE__;

	my $glob = do { no strict 'refs'; *{"::" . __PACKAGE__ . "::"} };

	# indentation clashes with the prettier sub decls
	my $src = Data::Dump::Streamer::Dump($glob)->Indent(0)->Out;

	# we don't really need this
	$src =~ s{ \$VAR1 \s* = .*? \n \*{'::${pkg}::'} \s* = .*? ;\n }{}sx;

	# sub decls can be a bit prettier
	$src =~ s{ ^ \* (?:${pkg}::)? ([\w:]+) \s* = \s* sub }{\nsub $1}gmx;

	Generate::PMC::File->new(
		input_file              => __FILE__,
		include_freshness_check => 0,
		body                    => [ join "\n\n",
			"package $pkg;",
			'BEGIN { $MO::Run::Aux::MO_NATIVE_RUNTIME = 1 }',
			$src,
			'1;',
			'',
		],
	)->write_pmc();
}

