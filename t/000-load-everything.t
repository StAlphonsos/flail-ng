#!/usr/bin/perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

use strict;
use warnings;
use Test::More tests => 9;

use t::lib;

require_ok("Flail");
require_ok("Flail::Config");
require_ok("Flail::Sink");
require_ok("Flail::App");
require_ok("Flail::App::Command");
require_ok("Flail::App::Command::ls");
require_ok("Flail::App::Command::repl");
require_ok("Flail::App::Command::server");
require_ok("Devel::REPL::Plugin::AppCmd");
