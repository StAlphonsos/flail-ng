#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::MessageSet - brief description

=head1 SYNOPSIS

  use Flail::MessageSet;
  blah;

=head1 DESCRIPTION

Describe the module with real words.


=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Flail::MessageSet;
use Moose;
use Flail::MessageSet::Maildir;
use Flail::MessageSet::Mu;

has "query" => (is => "rw", isa => "Maybe[Str]");
has "folder" => (is => "rw", isa => "Maybe[Str]");
has "page_size" => (is => "rw", isa => "Int", default => 0);
has "realization" => (
	is => "rw", isa => "Flail::MessageSet::Handler", weak_ref => 1,
	handles => [ "next", "prev", "first", "last", "count" ],
);

sub BUILD {
	my($self,$params) = @_;
	my $query = $self->query;
	my $folder = $self->folder;
	die("no query and no folder given") unless $query || $folder;
	if ($query && $folder) {
		$query .= " folder:$folder"; # xxx
	}
	if ($query) {
		$self->realization(
			Flail::MessageSet::Mu->new(query => $query));
	} else {
		$self->realization(
			Flail::MessageSet::Maildir->new(folder => $folder));
	}
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
