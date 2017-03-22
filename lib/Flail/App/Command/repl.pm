#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::App::Command::repl - read/eval/print loop

=head1 SYNOPSIS

  $ flail repl
  flail> 

=head1 DESCRIPTION

Implements a read/eval/print loop via L<Devel::REPL>

=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Flail::App::Command::repl;
use strict;
use warnings;
use Flail::App -command;
use Devel::REPL;

sub execute {
	my($self,$opt,$args) = @_;
	my $repl = Devel::REPL->new;
	$repl->prompt('flail> ');
	$repl->load_plugin('History');
	$repl->load_plugin('AppCmd');
	$repl->app_cmd($self->app);
	$repl->run;
}

1;

__END__
