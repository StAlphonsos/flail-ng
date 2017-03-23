#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

flail ls - list contents of Maildir folders

=head1 SYNOPSIS

  $ flail ls INBOX

=head1 DESCRIPTION


=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Flail::App::Command::ls;
use strict;
use warnings;
use Flail::App -command;

sub usage_desc { "flail ls [-options] [Maildir]" }

sub opt_spec {
	( [ "max|m=i" => "maximum number of entries to list" ],
	  [ "sort|s=s" => "sort by given field, default is msgid" ]
	);
}

sub execute {
	my($self,$opt,$args) = @_;
	my $maildir = shift(@$args) if @$args;
	my $max = $opt->{"max"};
	my $by = sub { $a cmp $b };
	if ($opt->{"sort"}) {
	}
	$maildir ||= $self->conf("maildir");
	$maildir = $self->path_to($maildir);
	my $folder = Mail::Box::Maildir->new(folder => $maildir);
	my @msgids = sort $by $folder->messageIds();
	$self->emit("folder '$folder':",scalar(@msgids),"messages");
	@msgids = @msgids[0..$max];
	foreach my $msgid (@msgids) {
		my $msg = $folder->messageId($msgid);
		
	}
}

1;

__END__
