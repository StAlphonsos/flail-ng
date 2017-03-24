#!/usr/bin/perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

use strict;
use warnings;
use Test::More tests => 2;
use vars qw($NO_MAILDIR);

BEGIN { $NO_MAILDIR = 1; }

use t::lib;

use Flail::Util qw(basename dirname);

is(basename("/foo/bar/bletch.quux"),"bletch.quux","basename works");
is(dirname("/foo/bar/bletch.quux"),"/foo/bar","dirname works");
