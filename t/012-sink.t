#!/usr/bin/perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

use strict;
use warnings;
use Test::More tests => 2;
use IO::String;
use vars qw($NO_MAILDIR);

BEGIN { $NO_MAILDIR = 1; }

use t::lib;

use Flail::Sink;

my $str = IO::String->new;
my $ref = $str->string_ref;
my $sink = Flail::Sink->new(stream => $str, debug => 1);
my $s = $sink->msg_to_string("foo");
is($s,"[flail] foo","msg_to_string('foo') looks right |$s|");
$sink->emit("bazle");
$sink->emit("!barfle");
$sink->emit("?bangle");
$sink->emit("#baffled");
my $exp = join("", <DATA>);
is($$ref,$exp,"result of four writes as expected |$$ref| vs |$exp|");

__DATA__
[flail] bazle
[flail] NOTICE barfle
[flail] ERROR bangle
[flail] DEBUG baffled
