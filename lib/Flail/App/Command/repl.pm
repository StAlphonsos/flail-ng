#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::App::Command::repl - read/eval/print loop

=head1 SYNOPSIS

  $ flail repl
  flail> # type flail commands here

=head1 DESCRIPTION

Implements a read/eval/print loop via L<Devel::REPL>

=cut

package Flail::App::Command::repl;
use Moose;
use Flail::App -command;
use Devel::REPL;

sub options { }

sub execute {
	my($self,$opt,$args) = @_;
	my $repl = Devel::REPL->new;
	$ENV{"FLAIL_LEVEL"} ||= 0;
	my $lvl = $ENV{"FLAIL_LEVEL"};
	++$ENV{"FLAIL_LEVEL"};
	my $prompt = "flail";
	$prompt .= "[$lvl]" if $lvl;
	$prompt .= "> ";
	$repl->prompt($prompt);
	$repl->load_plugin("History");
	$repl->load_plugin("AppCmd");
	$repl->app_cmd($self->the_app);
	$repl->run;
	--$ENV{"FLAIL_LEVEL"};
}

1;

__END__
