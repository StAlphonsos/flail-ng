#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::module - brief description

=head1 SYNOPSIS

  use Flail::module;
  blah;

=head1 DESCRIPTION

Describe the module with real words.

=cut

package Flail::module;
use Moose;

# to initialize an instance after construction:
sub BUILD {
	my($self,$params) = @_;
	# ... do stuff to $self
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

=pod

=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

__END__
