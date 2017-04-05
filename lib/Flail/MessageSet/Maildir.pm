#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::MessageSet::Maildir - brief description

=head1 SYNOPSIS

  use Flail::MessageSet::Maildir;
  blah;

=head1 DESCRIPTION

Describe the module with real words.

=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Flail::MessageSet::Maildir;
use Moose;
use Mail::Box::Maildir;

extends "Flail::MessageSet::Handler";

has "folder" => (is => "rw", isa => "Str", required => 1);
has "boxdir" => (is => "rw", isa => "Mail::Box::Dir");

sub BUILD {
	my($self,$params) = @_;
	$self->name($self->folder);
	$self->boxdir(Mail::Box::Maildir->new(folder => $self->folder));
}

# anonians
sub count	{ shift->boxdir->nrMessages() }
sub this	{ $_[0]->boxdir->message($_[0]->idx + $_[1]) }

__PACKAGE__->meta->make_immutable;

1;

__END__
