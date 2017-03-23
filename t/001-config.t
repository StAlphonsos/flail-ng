#!/usr/bin/perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

use strict;
use warnings;
use Test::More tests => 4;

use t::lib;

use Flail::Config;

my $c = Flail::Config->Default;
ok($c,"got a default config");
is($c->get("maildir"),"Maildir","maildir is Maildir");
is($c->get("maildir_base"),$ENV{"HOME"},"maildir_base is $ENV{HOME}");
is($c->get("foozle"),"","foozle is empty");
