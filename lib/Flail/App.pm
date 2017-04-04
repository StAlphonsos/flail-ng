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
use Moose;
use App::Cmd::Setup -app;
use Flail::Sink;
use Flail::Config;
use Flail::Util qw(dumpola);

has "sink" => (
	is => "rw", isa => "Flail::Sink", handles => [ qw[emit more] ]);
has "configuration" => (
	is => "rw", isa => "Flail::Config", handles => { 'conf' => 'get' });

sub BUILD {
	my($self,$params) = @_;
	$self->sink(Flail::Sink->Default);
	$self->configuration(Flail::Config->Default);
}

sub allow_any_unambiguous_abbrev { 1; }

1;

__END__
