#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::Reporter - base class for Flail objects

=head1 SYNOPSIS

  use Moose;
  extends "Flail::Reporter";
  ...
  sub something {
    my $self = shift;
    $self->log("!an error message");
    $self->log("a warning");
    $self->log("#debug spew");
  }

=head1 DESCRIPTION

Modeled on L<Mail::Reporter>, this class serves as a base class for
most Flail classes.  Its main job is to implement sane logging.

=cut

package Flail::Reporter;
use Moose;
use Scalar::Util qw(looks_like_number);
use Flail::Util qw(msgfy ts under_test_harness);
use vars qw(
    %LOG_LEVELS %LOG_LEVELS_LEAD %LOG_LEVELS_NUM $LOG_LEVEL_RE $LOG_STREAM
    $LOG_LEVEL %LEGAL_OPTS %LOG_OPTS $LOG_SUB);

with "Flail::Reporter::Role";

%LOG_LEVELS = (
	"debug" => [ 9, "#" ],
	"info" => [ 8, "*" ],
	"notice" => [ 7, ":" ],
	"warning" => [ 6, "" ],
	"error" => [ 5, "!" ],
	"fatal" =>  [ 4, "." ],
);
%LEGAL_OPTS = ( "ts" => 1, "nomarks" => 0 );
%LOG_OPTS = %LEGAL_OPTS;
%LOG_LEVELS_LEAD = (
	map { $LOG_LEVELS{$_}->[1] => [ $_, $LOG_LEVELS{$_}->[0] ] }
	grep { $_ ne "warning" }
	keys %LOG_LEVELS
);
%LOG_LEVELS_NUM = (
	map { $LOG_LEVELS{$_}->[0] => [ $_, $LOG_LEVELS{$_}->[1] ] }
	keys %LOG_LEVELS
);

$LOG_LEVEL_RE = qr/^([#\*:!\.])/;
$LOG_STREAM = undef;
$LOG_LEVEL = $LOG_LEVELS{"error"}->[0];

sub _spew { warn(@_) unless (under_test_harness() == 1)  }

$LOG_SUB = \&_spew;

sub _shut_log {
	return unless $LOG_STREAM;
	my $test = under_test_harness () ? " ($0 @ARGV)" : "";
	$LOG_STREAM->write("[".ts()."] <*> LOG STREAM TERMINATED${test}\n")
	    unless $LOG_OPTS{"nomarks"};
	$LOG_STREAM->close();
	$LOG_STREAM = undef;
}

END { _shut_log(); }

#__PACKAGE__->meta->make_immutable;

1;

__END__
