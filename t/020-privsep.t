#!/usr/bin/perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

# test basic functions of Flail::ChildProcess

use strict;
use warnings;
use Test::More tests => 38;
use Try::Tiny;
use POSIX qw(_exit);

use Flail::ChildProcess;

BEGIN { our $NO_MAILDIR = 1; }		# no test maildir for us

use t::lib;

package TestThing;
use Moose;
has "slot1" => (is => "rw", isa => "Str");
has "slot2" => (is => "rw", isa => "Int");
sub curse {
	my($self) = @_;
	return { "slot1" => $self->slot1, "slot2" => $self->slot2 };
}

package TestClass;
use Moose;
use TestThing;
use Flail::Util qw(dumpola);

sub unswiz {
	my($href) = @_;
	my $obj = TestThing->new(%$href);
	return $obj;
}
sub rpc_methods { { foo => \&unswiz, bar => \&unswiz, baz => undef } };
sub foo {
	my($self,$arg0) = @_;
	return TestThing->new(slot1 => "foo", slot2 => $arg0);
}
sub bar {
	my($self,$arg0) = @_;
	return TestThing->new(slot1 => "bar", slot2 => $arg0);
}
sub baz {
	my($self,@args) = @_;
	return { "ima" => "pig", "nargs" => scalar(@args) };
}


package main;

# 12 tests per call
sub test_the_things {
	my($obj,$invoker) = @_;
	my $rr = &$invoker($obj,"foo",42);
	is(ref($rr),"TestThing","right kind of ref returned");
	is($rr->slot1,"foo","slot1 is right");
	is($rr->slot2,42,"slot2 is right");

	$rr = &$invoker($obj,"bar",999);
	is(ref($rr),"TestThing","right kind of ref from bar");
	is($rr->slot1,"bar","slot1 is right");
	is($rr->slot2,999,"slot2 is right");

	$rr = &$invoker($obj,"baz","wow","wow","wow");
	is(ref($rr),"HASH","right kind of ref from bar");
	is(scalar(keys %$rr),2,"two keys in hashref");
	ok(exists($rr->{"nargs"}),"nargs is there");
	is($rr->{"nargs"},3,"nargs is right");
	ok(exists($rr->{"ima"}),"ima is there");
	is($rr->{"ima"},"pig","ima pig");
}

# single process:
my $obj1 = TestClass->new();
test_the_things($obj1, sub { my($o,$m,@a) = @_; $o->$m(@a) });		# +12

# privsep'd
my $obj2 = TestClass->new();
my $proc;
#$SIG{CHLD} = sub {
#	while ((my $pid = waitpid(-1, WNOHANG)) > 0) {
#		my($signo,$coredump,$xit) = ($? & 127,$? & 128,$? >> 8);
#		warn("reaped $pid, sig $signo core $coredump xit $xit\n");
#		$proc->finish(
#			do_wait => 0,
#			signo => $signo,
#			coredump => $coredump,
#			xit => $xit) if $proc && $proc->pid == $pid;
#	}
#};
$proc = Flail::ChildProcess->new(
	"obj" => $obj2,
	"name" => "privsep test process",
	"promises" => "stdio");
_exit($proc->loop) if $proc->in_child;
if (verbose()) { my $it = $proc->pid; sleep(1); system("ps $it"); }
test_the_things($proc,sub { my($o,$m,@a) = @_; $o->req($m,@a); });	# +12

try {
	my @rez = $proc->req("bazle",1);
	ok(0,"invoking bazle won?");					# +1
} catch {
	ok("@_","invoking nonexistent method bazle failed: @_");
};
test_the_things($proc,sub { my($o,$m,@a) = @_; $o->req($m,@a); });	# +12

is($proc->finish(),0,"finish won");					# +1
