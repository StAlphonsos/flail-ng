#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::Sink - a place to send output

=head1 SYNOPSIS

  Flail::Sink->Default->write("foo!");
  # prints: [flail] foo!

=head1 DESCRIPTION

Describe the module with real words.


=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Flail::Sink;
use Moose;
use IO::Handle;
use vars qw($DEFAULT_SINK %LEAD_TRAIL);

%LEAD_TRAIL = (
	"normal" => [ "[flail] ", "" ],
	"notice" => [ "[flail NOTICE] ", "" ],
	"error" => [ "[flail ERROR] ", "" ],
	"debug" => [ "[flail DEBUG] ", "" ],
);

has "eol" => (is => "rw", isa => "Str", default => "\n");
has "sep" => (is => "rw", isa => "Str", default => " ");
has "stream" => (is => "ro", isa => "Object", required => 1);
has "debug" => (is => "rw", isa => "Bool", default =>$ENV{"TEST_VERBOSE"}?1:0);

sub BUILD {
	my($self,$params) = @_;
	$self->stream->autoflush(1);
}

sub Default {
	$DEFAULT_SINK ||=
	    shift->new(stream => IO::Handle->new_from_fd(fileno(STDOUT),"w"));
	$DEFAULT_SINK;
}

sub leader {
	my($self,$style) = @_;
	return $LEAD_TRAIL{$style}->[0] if exists $LEAD_TRAIL{$style};
	return $style? "[flail ?${style}?] ": "[flail?] ";
}

sub trailer {
	my($self,$style) = @_;
	return $LEAD_TRAIL{$style}->[1] if exists $LEAD_TRAIL{$style};
	return "";
}

sub msg_to_string {
	my($self,@msg) = @_;
	return "" unless @msg;
	my $c0 = substr("$msg[0]",0,1);
	my $style = "normal";
	if    ($c0 eq '!') { $style = "notice"; $msg[0]=substr($msg[0],1); }
	elsif ($c0 eq '?') { $style = "error";  $msg[0]=substr($msg[0],1); }
	elsif ($c0 eq '#') { $style = "debug";  $msg[0]=substr($msg[0],1); }
	return undef if ($style eq "debug") && !$self->debug;
	return $self->leader($style) . join($self->sep, @msg) .
	    $self->trailer($style);
}

sub write {
	my($self,@msg) = @_;
	my $str = $self->msg_to_string(@msg);
	return unless defined $str;
	$str .= $self->eol if $self->eol && substr($str,-1,1) ne $self->eol;
	$self->stream->write($str);
}

__PACKAGE__->meta->make_immutable;

1;

__END__
