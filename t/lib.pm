#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

package main;
use strict;
use warnings;
use File::Path qw(make_path remove_tree);
use Data::Dumper;
use POSIX;

sub ts { POSIX::strftime("%Y-%m-%dT%H:%M:%S%Z",localtime(time)) }

sub setup_testing_env {
	my $tmpd = $ENV{"TMPDIR"} || "/tmp";
	if (exists($ENV{"FLAIL_TEST_TESTDIR"})) {
		my $td = $ENV{"FLAIL_TEST_TESTDIR"};
		die("you set FLAIL_TEST_TESTDIR=$td but it does not exist!")
		    unless -d $td;
		$ENV{"FLAIL_TEST_TESTDIR_SET"} = 0;
	} else {
		my $outd = $tmpd . "/flail_test_outdir.$$";
		die("setup_testing_env: $outd exists!")
		    if (-d $outd || -f $outd);
		make_path($outd)
		    or die("setup_testing_env: mkdir $outd: $!");
		$ENV{"FLAIL_TEST_TESTDIR"} = $outd;
		$ENV{"FLAIL_TEST_TESTDIR_SET"} = 1;
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

setup_testing_env unless $ENV{"FLAIL_TEST_NO_SETUP"};

1;
