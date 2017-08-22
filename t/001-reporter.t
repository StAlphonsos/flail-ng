#!/usr/bin/perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

use Modern::Perl;
use Test::More tests => 11;
use IO::String;
use vars qw($NO_MAILDIR $NO_LOGFILE);
BEGIN { $NO_MAILDIR = 1; $NO_LOGFILE = 1; }

use t::lib;

Flail::Reporter->log_options(ts => 0,nomarks => 1);

package Whatsit;
use Moose;
extends "Flail::Reporter";
has "x" => (is => "rw", isa => "Int", default => 0);
has "y" => (is => "rw", isa => "Int", default => 0);

sub mung {
	$_[0]->log("#munging the thing");
	$_[0]->x($_[1]);
	$_[0]->log("munged x");
	$_[0]->y($_[2]);
	$_[0]->log("!munged y");
}

package main;
sub capture {
	my($code,@args) = shift;
	my $stream = IO::String->new;
	my $ref = $stream->string_ref;
	Flail::Reporter->log_to($stream);
	&$code(@args);
	return $$ref;
}
my $x = Whatsit->new;
my $c = capture(sub { $x->mung(2,3) });
is($x->x,2,"modified x properly");
is($x->y,3,"modified y properly");
is($c,"<error> munged y\n","captured the right thing: $c");
ok($x->log_level("warning"),"set log level to warning");
$c = capture(sub { $x->mung(4,5) });
is($x->x,4,"modified x");
is($x->y,5,"modified y");
is($c,"<warning> munged x\n<error> munged y\n","captured the right thing: $c");
ok(Flail::Reporter->log_level("debug"),"class method log_level worked");
$c = capture(sub { $x->mung(6,7) });
is($x->x,6,"modified x");
is($x->y,7,"modified y");
is($c,"<debug> munging the thing\n<warning> munged x\n<error> munged y\n",
   "captured the right thing: $c");
