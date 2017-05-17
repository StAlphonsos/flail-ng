#!/usr/bin/perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

use Modern::Perl;
use Test::More tests => 1;
use vars qw($NO_MAILDIR);
BEGIN { $NO_MAILDIR = 1; }

use t::lib;

ok(something(),"something won");
