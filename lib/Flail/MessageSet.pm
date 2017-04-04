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
use Flail::Util qw(dumpola test_warn);
use overload '""' => sub { "" . shift->real };

has "query" => (is => "rw", isa => "Maybe[Str]");
has "folder" => (is => "rw", isa => "Maybe[Str]");
has "real" => (
	is => "rw", isa => "Flail::MessageSet::Handler",
	handles => [ qw[count this finish first final next prev] ]);

sub BUILD {
	my($self,$params) = @_;
	$self->real(Flail::MessageSet::Maildir->new(folder => $self->folder));
}

sub Query	{ shift->new(@_) }

__PACKAGE__->meta->make_immutable;

1;

__END__
