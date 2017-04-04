#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::Message - wrapper around Mail::Intenret

=head1 SYNOPSIS

  use Flail::Message;
  blah;

=head1 DESCRIPTION

Describe the module with real words.

=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Flail::Message;
use Moose;
use Flail::Util qw(single);
use vars qw($SUMMARY_SEP @SUMMARY_FIELDS);
use overload '""' => \&to_string;

$SUMMARY_SEP = "|";
@SUMMARY_FIELDS = qw(timestamp from subject);

has "real" => (
	is => "rw", isa => "Mail::Message",
	handles => [qw[subject messageId]]);

sub to_string {
	my($self) = @_;
	join($SUMMARY_SEP,
	     map { sprintf("%s:%s", ucfirst($_), single($self->real->$_)) }
	     @SUMMARY_FIELDS);
}

# to mung args on their way to the constructor:
around BUILDARGS => sub {
	my $orig = shift;
	my $class = shift;
	my $args;
	if (@_ == 1 && ref($_[0]) eq 'HASH') {
		$args = shift;
	} elsif (@_ == 1) {
		$args = { "real" => shift };
	} else {
		$args = { @_ };
	}
	return $args;
};

__PACKAGE__->meta->make_immutable;

1;

__END__
