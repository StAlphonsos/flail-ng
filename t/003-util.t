#!/usr/bin/perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

use strict;
use warnings;
use Test::More tests => 20;
use vars qw($NO_MAILDIR);

BEGIN { $NO_MAILDIR = 1; }

use t::lib;

use Flail::Util qw(:all);

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

is(clean("  abc  \n "),"abc","clean works");

is(affirmative("yes"),1,"affirmative('yes')");
is(affirmative("no"),0,"affirmative('no')");

is(msgfy(undef),"-UNDEF-","msgfy(undef)");
is(msgfy("foo"),"foo","msgfu('foo')");

my($w,$h) = screen_columns();
ok($w,"terminal width defined=$w");
ok($h,"terminal height non-zero=$h");

is(defor(undef,"default"),"default","defor works 1");
is(defor("foo","default"),"foo","defor works 2");

my $href = { "abc" => 123, "xyz" => 0, "qqq" => undef };
is(defkey($href,"abc",999),123,"defkey 1 okay");
is(defkey($href,"zzz",999),999,"defkey 2 okay");
is(defkey($href,"qqq",999),undef,"defkey 3 okay");
is(defkey($href,"xyz",999),0,"defkey 4 okay");
