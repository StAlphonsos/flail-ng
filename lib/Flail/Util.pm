#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::Util - utilities without any other natural home

=head1 SYNOPSIS

  use Flail::Util;
  blah;

=head1 DESCRIPTION

Describe the module with real words.


=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Flail::Util;
use Data::Dumper;
use POSIX;
use Scalar::Util qw(looks_like_number);
use parent qw(Exporter);
use vars qw(@EXPORT_OK %EXPORT_TAGS $TIME_FMT);

$TIME_FMT = "%Y-%m-%d %H:%M:%S";
@EXPORT_OK = qw(
    affirmative basename basename_env clean dirname dirname_env
    dumpola msgfy ts screen_columns test_warn);
%EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

sub basename	{ (split(/\//, $_[0]))[-1] }
sub dirname	{ my @p = split(/\//, $_[0]); join("/", @p[0..$#p-1]); }

sub basename_env{
	return basename($ENV{$_[0]}) if exists $ENV{$_[0]};
	shift;
	return @_ ? basename_env(@_) : undef;
}

sub dirname_env {
	return dirname($ENV{$_[0]}) if exists $ENV{$_[0]};
	shift;
	return @_ ? dirname_env(@_) : undef;
}

sub dumpola { Data::Dumper->new(\@_)->Terse(1)->Indent(0)->Dump; }
sub test_warn { warn("@_\n") if $ENV{"TEST_VERBOSE"} }

sub clean { my($s) = @_; $s =~ s/(^\s+|\s+$)//gs; $s }
sub affirmative { ($_[0] =~ /^(yes|t|ok|)$/i) ? 1 : 0 }

sub msgfy {
	my($what) = @_;
	return "-UNDEF-"	unless defined $what;
	return "$what"		unless     ref $what;
	return dumpola($what);
}

sub ts		{ POSIX::strftime($TIME_FMT,localtime(shift || time)) }

sub screen_columns {
	my($width,$height);
	unless (exists $ENV{'CGI'}) {
		if (-t 0) {
			chomp(my $line = `/bin/stty -a | /usr/bin/head -1`);
			($width,$height) = ($2,$1)
			    if $line =~ /;\s(\d+)\srows;\s(\d+)\scol/;
		}
	}
	return($width,$height);
}

1;

__END__
