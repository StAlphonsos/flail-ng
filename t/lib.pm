#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

package main;
use strict;
use warnings;
use File::Path qw(make_path remove_tree);
use Data::Dumper;
use POSIX;
use vars qw($NO_MAILDIR $SAMPLE_MAILDIR);

$NO_MAILDIR ||= 0;
$SAMPLE_MAILDIR ||= "maildir_simple";

sub ts		{ POSIX::strftime("%Y-%m-%dT%H:%M:%S%Z",localtime(time)) }
sub DD		{ Data::Dumper->new(\@_)->Terse(1)->Indent(0)->Dump; }
sub verbose	{ $ENV{"TEST_VERBOSE"} }
sub test_folder	{ $ENV{"FLAIL_TEST_MAILDIR"} }

sub setup_testing_env {
	my $tmpd = $ENV{"TMPDIR"} || "/tmp";
	my $tstd;
	if (exists($ENV{"FLAIL_TEST_TESTDIR"})) {
		$tstd = $ENV{"FLAIL_TEST_TESTDIR"};
		die("you set FLAIL_TEST_TESTDIR=$tstd but it does not exist!")
		    unless -d $tstd;
		$ENV{"FLAIL_TEST_TESTDIR_SET"} = 0;
	} else {
		$tstd = $tmpd . "/flail_test_dir.$$";
		die("setup_testing_env: $tstd exists!")
		    if (-d $tstd || -f $tstd);
		make_path($tstd)
		    or die("setup_testing_env: mkdir $tstd: $!");
		$ENV{"FLAIL_TEST_TESTDIR"} = $tstd;
		$ENV{"FLAIL_TEST_TESTDIR_SET"} = 1;
	}
	# tests that don't want a Maildir set up must BEGIN { $NO_MAILDIR=1 }
	# c.f. 000-load-everything.t
	unless ($NO_MAILDIR) {
		my $fix = "t/fixtures/${SAMPLE_MAILDIR}";
		my $md = join("/", $tstd, "Maildir");
		warn("# populating $md from $fix ...\n") if verbose;
		die("setup_testing_env: $md exists!") if -d $md || -f $md;
		make_path($md) or die("make_path($md): $!");
		die("$fix is missing") unless -d $fix;
		my $tar = $ENV{'FLAIL_TEST_TAR'} || 'tar';
		my $xf = verbose() ? 'xvf' : 'xf';
		my $cmd = qq{sh -c '(cd $fix; }.
		    qq{${tar} -cf - .) | (cd $md; ${tar} -$xf -)'};
		system($cmd) == 0 or die("seutp_testing_env: $cmd: $!");
		$ENV{"FLAIL_TEST_MAILDIR"} = $md;
		$ENV{"MAILDIR"} = $md;
	}
}

END {
	if ($ENV{"FLAIL_TEST_TESTDIR"}) {
		if ($ENV{"FLAIL_TEST_KEEP_TESTDIR"}) {
			diag("Kept output dir: $ENV{FLAIL_TEST_TESTDIR}");
		} elsif ($ENV{"FLAIL_TEST_TESTDIR_SET"}) {
			remove_tree($ENV{"FLAIL_TEST_TESTDIR"},
				    { verbose => $ENV{"TEST_VERBOSE"} });
		}
	}
}

setup_testing_env() unless $ENV{"FLAIL_TEST_NO_SETUP"};

1;
