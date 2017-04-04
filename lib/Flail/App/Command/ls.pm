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
use Modern::Perl;
use Flail::App -command;
use Flail::MessageSet;

sub usage_desc { "flail ls [-options] [Maildir]" }

sub options {
	( [ "max|m=i" => "maximum number of entries to list",
	    { default => 20 } ],
	  [ "sort|s=s" => "sort by given field, default is msgid" ],
	);
}

sub query_params {
	my($self,$opt,$args) = @_;
	my %qopts;
	my $maildir = shift(@$args) if @$args;
	$maildir ||= $opt->{"maildir"} || $self->conf("maildir");
	$self->emit("# maildir: $maildir");
	$qopts{"folder"} = $maildir;
	$self->emit("# folder: $qopts{folder}");
	return %qopts;
}

sub execute {
	my($self,$opt,$args) = @_;
	$self->emit("# ls::execute opt=",$opt,"args=",$args);
	my %qparams = $self->query_params($opt,$args);
	my $mset = Flail::MessageSet->Query(%qparams);
	my $page = $self->emit(page_start => $mset);
	my $result = $mset->first;
	while ($result) {
		$page->emit(row => $result);
		if ($page->is_full && !$mset->is_exhausted) {
			$page = $page->emit(page_end => $mset)->more();
			last unless $page;
		}
		$result = $mset->next;
	}
	$self->emit(page_end => $mset);
}

1;

__END__
