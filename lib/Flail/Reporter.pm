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
use Modern::Perl;
use Moose;
use Scalar::Util qw(looks_like_number);
use Flail::Util qw(msgfy ts under_test_harness);
use vars qw(
    %LOG_LEVELS %LOG_LEVELS_LEAD %LOG_LEVELS_NUM $LOG_LEVEL_RE $LOG_STREAM
    $LOG_LEVEL %LEGAL_OPTS %LOG_OPTS $LOG_SUB);

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

=pod

=over 4

=item * $self->log($msg,...);

=back

=cut

sub log {
	my $me = shift;
	if (!@_) {
		&$LOG_SUB(" -empty message-");
		return;
	}
	my($msg,@xtra) = @_;
	$msg = "$msg";
	my $lvl = "warning";
	if ($msg =~ $LOG_LEVEL_RE) {
		$lvl = $LOG_LEVELS_LEAD{$1}->[0];
		$msg = substr($msg,1);
	}
	return unless $LOG_LEVEL >= $LOG_LEVELS{$lvl}->[0];
	my $ts = $LOG_OPTS{"ts"} ? "[".ts()."] " : "";
	$msg = $ts . "<$lvl> ". $msg . msgfy(@xtra);
	$msg .= "\n" unless $msg =~ /\n$/;
	$LOG_STREAM->write($msg) if $LOG_STREAM;
	&$LOG_SUB($msg);
}

=pod

=over 4

=item * $self_or_class->log_level [$new_level]


=back

=cut

sub log_level {
	my $me = shift;
	return $LOG_LEVEL unless @_;
	my $lv = shift;
	my $level;
	if (looks_like_number($lv)) {
	    if (exists($LOG_LEVELS_NUM{$lv})) {
		    $level = $LOG_LEVELS_NUM{$lv}->[0];
	    }
	} elsif (exists($LOG_LEVELS{$lv})) {
		$level = $lv;
	}
	die("$me log_level called with strange arg: |$lv|")
	    unless defined $level;
	my $prev = $LOG_LEVEL;
	$LOG_LEVEL = $LOG_LEVELS{$level}->[0];
	return $prev;
}

sub _shut_log {
	return unless $LOG_STREAM;
	my $test = under_test_harness () ? " ($0 @ARGV)" : "";
	$LOG_STREAM->write("[".ts()."] <*> LOG STREAM TERMINATED${test}\n")
	    unless $LOG_OPTS{"nomarks"};
	$LOG_STREAM->close();
	$LOG_STREAM = undef;
}

=pod

=over 4

=item * log_to $stream_or_path

=back

=cut

sub log_to {
	my($me,$fn) = @_;
	_shut_log();
	$LOG_STREAM = ref($fn) ? $fn : IO::File->new(">> $fn");
	$LOG_STREAM->autoflush(1);
	if (!ref($fn)) {
		my $test = under_test_harness () ? " ($0 @ARGV)" : "";
		$LOG_STREAM->write("[".ts()."] <*> LOG => ${fn}${test}\n")
		    unless $LOG_OPTS{"nomarks"};
	}
}

=pod

=over 4

=item * log_options [ts => 1|0]

=back

=cut

sub log_options {
	my($me,%opts) = @_;
	foreach my $key (keys %opts) {
		$LOG_OPTS{$key} = $opts{$key} if exists $LEGAL_OPTS{$key};
	}
}

END { _shut_log(); }

__PACKAGE__->meta->make_immutable;

1;

__END__
