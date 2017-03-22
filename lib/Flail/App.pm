#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::App - top-level application object for flail

=head1 SYNOPSIS

  Flail::App->run;

=head1 DESCRIPTION

Blah.

=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Flail::App;
use strict;
use warnings;
use App::Cmd::Setup -app;

sub allow_any_unambiguous_abbrev { 1; }

1;

__END__
