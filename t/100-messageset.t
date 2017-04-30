#!/usr/bin/perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

use strict;
use warnings;
use Test::More tests => 33;

use t::lib;

use Flail::MessageSet;
use Flail::MessageSet::Maildir;

my %EXPECT = (
	COUNT => 2,
	ID0 => '20141116170227.009E97A71F47@elabs10.com',
	SUBJ0 => "Slashdot Newsletter 2014-11-16",
	ID1 => 'alpine.BSO.2.20.1506281513280.27877@morgaine.local',
	SUBJ1 => "Re: C-state FFH on x41",
);

# 11 tests per call
sub test_mset {
	my($cname,@args) = @_;
	my $mclass = "Flail::MessageSet";
	$mclass .= "::${cname}" if $cname;
	$cname ||= "generic";
	my $mset = $mclass->new(@args);
	ok($mset,"$cname message set created: @args");
	is($mset->count,$EXPECT{COUNT},
	   "$cname count is as expected: ".$mset->count);
	my $m0 = $mset->first;
	ok($m0,"got first message $m0");
	is($m0->subject,$EXPECT{SUBJ0},"subject 0 is as excected");
	my $m0id = $m0->messageId;
	is($m0id,$EXPECT{ID0},"message-id is right");
	my $m_1=$mset->final;
	ok($m_1,"got final message");
	isnt("$m0","$m_1","m0 != m-1"); # not sure this is right
	my $m1id = $m_1->messageId;
	isnt($m0id,$m1id,"message ids are not the same");
	is($m_1->subject,$EXPECT{SUBJ1},"subject is right for m-1");
	is($m1id,$EXPECT{ID1},"id is right");
	ok($mset->finish,"finish won for $cname");
}

test_mset("Maildir", folder => test_folder);			#   11
test_mset("", folder => test_folder, no_privsep => 1);		# + 11
test_mset("", folder => test_folder);				# + 11
