#!/usr/bin/perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

use Modern::Perl;
use Test::More;
use vars qw($NO_MAILDIR);

BEGIN { $NO_MAILDIR = 1; }

# programmatically get the list of modules and require_ok them all
# that way we don't have to constantly edit this test

open(MAN,"MANIFEST") or die "MANIFEST: $!";
our @LIST =(map { $_ =~ s,^lib/,,; $_ =~ s,/,::,g; $_ =~ s/\.pm$//; $_; }
	    grep {/^lib/} <MAN>);
close(MAN);

use t::lib;

require_ok($_) foreach (@LIST);
done_testing(scalar(@LIST));
