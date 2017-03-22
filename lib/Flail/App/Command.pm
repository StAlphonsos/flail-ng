#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::App::Command - base class for commands

=head1 SYNOPSIS

  use Flail::module;
  blah;

=head1 DESCRIPTION

Describe the module with real words.


=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Flail::App::Command;
use App::Cmd::Setup -command;

sub emit {
	shift if ref($_[0]);
	print "[emit] @_\n";
}

1;

__END__
