#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::Reporter::Role - logging methods

=head1 SYNOPSIS

  package Something;
  use Moose;
  use MooseX::NonMoose;

  # extending some non-Moose class
  extends "Something::Non::Moosient";
  # ... but still want logging
  with "Flail::Reporter::Role;


=head1 DESCRIPTION

This Role contains all of the logging methods in a form that can be
consumed as a role by classes that extend non-Moose classes, such
as Flail::App and Flail::App::Command.  In these cases we cannot
extend L<Flail::Reporter> because we are extending a non-Moose class,
so instead we consume this role.

Moose-based classes should extend L<Flail::Reporter> instead; all it
does is consume this role and provide a home for the state it needs.

=cut

package Flail::Reporter::Role;
use Moose::Role;
use Scalar::Util qw(looks_like_number);
use Flail::Util qw(msgfy ts under_test_harness);
use Flail::Reporter;

=pod

=over 4

=item * $self->log($msg,...);

=back

=cut

sub log {
	my $me = shift;
	if (!@_) {
		&$Flail::Reporter::LOG_SUB(" -empty message-");
		return;
	}
	my($msg,@xtra) = @_;
	$msg = "$msg";
	my $lvl = "warning";
	if ($msg =~ $Flail::Reporter::LOG_LEVEL_RE) {
		$lvl = $Flail::Reporter::LOG_LEVELS_LEAD{$1}->[0];
		$msg = substr($msg,1);
	}
	return unless ($Flail::Reporter::LOG_LEVEL >=
		       $Flail::Reporter::LOG_LEVELS{$lvl}->[0]);
	my $ts = $Flail::Reporter::LOG_OPTS{"ts"} ? "[".ts()."] " : "";
	$msg = $ts . "<$lvl> ". $msg . msgfy(@xtra);
	$msg .= "\n" unless $msg =~ /\n$/;
	$Flail::Reporter::LOG_STREAM->write($msg)
	    if $Flail::Reporter::LOG_STREAM;
	&$Flail::Reporter::LOG_SUB($msg);
}

=pod

=over 4

=item * $self_or_class->log_level [$new_level]


=back

=cut

sub log_level {
	my $me = shift;
	return $Flail::Reporter::LOG_LEVEL unless @_;
	my $lv = shift;
	my $level;
	if (looks_like_number($lv)) {
	    if (exists($Flail::Reporter::LOG_LEVELS_NUM{$lv})) {
		    $level = $Flail::Reporter::LOG_LEVELS_NUM{$lv}->[0];
	    }
	} elsif (exists($Flail::Reporter::LOG_LEVELS{$lv})) {
		$level = $lv;
	}
	die("$me log_level called with strange arg: |$lv|")
	    unless defined $level;
	my $prev = $Flail::Reporter::LOG_LEVEL;
	$Flail::Reporter::LOG_LEVEL =
	    $Flail::Reporter::LOG_LEVELS{$level}->[0];
	return $prev;
}

=pod

=over 4

=item * log_to $stream_or_path

=back

=cut

sub log_to {
	my($me,$fn) = @_;
	Flail::Reporter::_shut_log();
	$Flail::Reporter::LOG_STREAM = ref($fn) ?
	    $fn : IO::File->new(">> $fn");
	$Flail::Reporter::LOG_STREAM->autoflush(1);
	if (!ref($fn)) {
		my $test = under_test_harness () ? " ($0 @ARGV)" : "";
		$Flail::Reporter::LOG_STREAM->write("[".ts()."] <*> ".
						    "LOG => ${fn}${test}\n")
		    unless $Flail::Reporter::LOG_OPTS{"nomarks"};
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
		$Flail::Reporter::LOG_OPTS{$key} = $opts{$key}
		    if exists $Flail::Reporter::LEGAL_OPTS{$key};
	}
}

1;

__END__
