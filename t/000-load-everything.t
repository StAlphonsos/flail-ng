#!/usr/bin/perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

use strict;
use warnings;
use Test::More tests => 14;
use vars qw($NO_MAILDIR);

BEGIN { $NO_MAILDIR = 1; }

use t::lib;

require_ok("Flail");
require_ok("Flail::Config");
require_ok("Flail::MessageSet");
require_ok("Flail::MessageSet::Handler");
require_ok("Flail::MessageSet::Maildir");
require_ok("Flail::MessageSet::Mu");
require_ok("Flail::Sink");
require_ok("Flail::App");
require_ok("Flail::App::Command");
require_ok("Flail::App::Command::ls");
require_ok("Flail::App::Command::repl");
require_ok("Flail::App::Command::server");
require_ok("Flail::Util");
require_ok("Devel::REPL::Plugin::AppCmd");
