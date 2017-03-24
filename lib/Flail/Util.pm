#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::Util - brief description

=head1 SYNOPSIS

  use Flail::Util;
  blah;

=head1 DESCRIPTION

Describe the module with real words.


=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Flail::Util;
use parent qw(Exporter);
use vars qw(@EXPORT_OK);

@EXPORT_OK = qw(basename dirname);

sub basename	{ (split(/\//, $_[0]))[-1] }
sub dirname	{ my @p = split(/\//, $_[0]); join("/", @p[0..$#p-1]); }
	
1;

__END__
