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

=cut

package Flail::App::Command;
use Moose;
use App::Cmd::Setup -command;
use Flail::Util qw(dumpola);

extends "Flail::Reporter";

has "the_app" => (
	is => "rw", isa => "Object", handles => [qw[emit more is_full conf]]);

sub BUILD {
	my($self,$params) = @_;
	$self->the_app($params->{"app"});
}

sub opt_spec {
	my($class,$app) = @_;
	return ( [ "verbose|v" => "crank up verbosity in output" ],
		 [ "debug|d" => "turn on debugging" ],
		 [ "maildir|m=s" => "Maildir base (def: ~/Maildir)" ],
		 [ "config|C=s" => "use config in given file (def ~/.flailrc)",
		   { default => join("/",$ENV{"HOME"},".flailrc") } ],
		 $class->options($app) );
}

1;

__END__
