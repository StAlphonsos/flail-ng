#!/usr/bin/perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

use strict;
use warnings;
use Test::More tests => 7;
use vars qw($NO_MAILDIR);

BEGIN { $NO_MAILDIR = 1; }

use t::lib;

use Flail::Util qw(basename dirname basename_env dirname_env);

is(basename("/foo/bar/bletch.quux"),"bletch.quux","basename works");
is(dirname("/foo/bar/bletch.quux"),"/foo/bar","dirname works");

$ENV{"FLORB"} = "/wow/this/sucks";
$ENV{"BLORB"} = "/and/this/too";
delete $ENV{"SLORB"} if exists $ENV{"SLORB"}; # perverts
delete $ENV{"GLORB"} if exists $ENV{"GLORB"}; # rilly?

is(basename_env("FLORB"),"sucks","basename_env 1");
is(basename_env("BLORB","FLORB"),"too","basename_env 2");
is(basename_env("SLORB"),undef,"basename_env 3");
is(dirname_env("SLORB","BLORB","FLORB"),"/and/this","dirname_env 1");
is(dirname_env("GLORB","SLORB","BLORB"),"/and/this","dirname_env 2");
