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
use Moose;
use App::Cmd::Setup -command;
use Flail::Sink;
use Flail::Config;

has "sink" => (
	is => "rw", isa => "Object", default => sub { Flail::Sink->Default });
has "configuration" => (
	is => "rw", isa => "Object", default => sub { Flail::Config->Default});

sub opt_spec {
	my($class,$app) = @_;
	return ( [ "verbose|v" => "crank up verbosity in output" ],
		 [ "config|C=s" => "use config in given file (def ~/.flailrc)",
		   { default => join("/",$ENV{"HOME"},".flailrc") } ],
		 $class->options($app) );
}

sub emit { shift->sink->write(@_) }
sub conf { shift->configuration->get(@_) }

1;

__END__
