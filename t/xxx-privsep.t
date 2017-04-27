#!/usr/bin/perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

use strict;
use warnings;
use Test::More tests => 14;
use Try::Tiny;
use Flail::ChildProcess;

BEGIN { our $NO_MAILDIR = 1; }

use t::lib;

package TestClass;
use Moose;
sub rpc_methods { { foo => {}, bar => {} } };
sub foo {
	my($self,$arg0) = @_;
	return 123;
}
sub bar {
	my($self,@args) = @_;
	return { "ima" => "pig", "nargs" => scalar(@args) };
}

package main;

my $obj = TestClass->new();
ok($obj,"got a test object $obj");
my $rr = $obj->foo(42);
is($rr,123,"invoking foo in parent works");
$rr = $obj->bar("a string",57,"a third arg");
ok($rr,"bar in parent returns something");
is(ref($rr),"HASH","bar returns right thing");
is_deeply($rr,{ "ima" => "pig", "nargs" => 3 },"right response from bar");

my $child = Flail::ChildProcess->new(
	"name" => "privsep test process",
	"promises" => "stdio");
if ($child->in_child) {
	exit($child->loop($obj));
}
if (verbose()) { my $it = $child->pid; sleep(1); system("ps $it"); }
my @rez = $child->req("foo",42);
ok(scalar(@rez),"got a response from foo rpc: @rez");
is(scalar(@rez),1,"right number of results from foo");
is($rez[0],123,"got the RIGHT response from foo rpc");
@rez = $child->req("bar","a string",57,"a third arg");
ok(scalar(@rez),"got a response from bar rpc: @rez");
is(scalar(@rez),1,"got right number of results from bar");
is(ref($rez[0]),"HASH","got a hashref from bar");
is_deeply($rez[0],{ "ima" => "pig", "nargs" => 3 },"right response from bar");

try {
	@rez = $child->req("bazle",1);
	ok(0,"invoking bazle won?");
} catch {
	ok("@_","invoking nonexistent method bazle failed: @_");
};

ok($child->finish(),"finish won");
