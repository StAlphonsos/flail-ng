#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::MessageSet::Mu - brief description

=head1 SYNOPSIS

  use Flail::MessageSet::Mu;
  blah;

=head1 DESCRIPTION

Describe the module with real words.

=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Flail::MessageSet::Mu;
use Moose;
use mup;

extends "Flail::MessageSet::Handler";

has "query" => (is => "rw", isa => "Str", required => 1);
has "mup" => (is => "rw", isa => "mup");

# to initialize an instance after construction:
sub BUILD {
	my($self,$params) = @_;
}

# to mung args on their way to the constructor:
around BUILDARGS => sub {
	my $orig = shift;
	my $class = shift;
	my $args;
	if (@_ == 1 && ref($_[0]) eq 'HASH') {
		$args = shift;
	} else {
		$args = { @_ };
	}
	# do something with args here
	return $args;
};

__PACKAGE__->meta->make_immutable;

1;

__END__
