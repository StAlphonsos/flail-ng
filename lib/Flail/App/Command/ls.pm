#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

flail ls - list contents of Maildir folders

=head1 SYNOPSIS

  $ flail ls INBOX

=head1 DESCRIPTION

List messages in a Maildir folder

=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Flail::App::Command::ls;
use strict;
use warnings;
use Flail::App -command;
use Mail::Box::Maildir;

sub usage_desc { "flail ls [-options] [Maildir]" }

sub options {
	( [ "max|m=i" => "maximum number of entries to list",
	    { default => 20 } ],
	  [ "sort|s=s" => "sort by given field, default is msgid" ],
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
	$maildir = join("/", $self->conf("maildir_base"), $maildir);
	my $folder = Mail::Box::Maildir->new(folder => $maildir);
	my @msgids = sort $by $folder->messageIds();
	$self->emit("folder '$folder':",scalar(@msgids),"messages");
	@msgids = @msgids[0..$max] if $max;
	foreach my $msgid (@msgids) {
		my $msg = $folder->messageId($msgid);
		my @from = $msg->from();
		my @to = $msg->to();
		my $date = $msg->head->date;
		my $subj = $msg->study('subject');
		my $from_str = shift(@from)->format(@from);
		my $to_str = shift(@to)->format(@to);
		$self->emit($msgid,$date,$from_str,$to_str,$subj);
	}
}

1;

__END__
