#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::App::Command::server - flail server command

=head1 SYNOPSIS

  $ flail server

=head1 DESCRIPTION

The flail server can be run on the machine to which your mail is
delivered.

=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Flail::App::Command::server;
use strict;
use warnings;
use Flail::App -command;

sub execute {
	my($self,$opt,$args) = @_;
	$self->emit("server command not yet implemented");
}

1;

__END__
