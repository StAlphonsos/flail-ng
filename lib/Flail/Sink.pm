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
use Flail::Util qw(affirmative clean msgfy screen_columns);
use vars qw($DEFAULT_SINK %LEAD_TRAIL);

%LEAD_TRAIL = (
	"normal" => [ "[flail] ", "" ],
	"notice" => [ "[flail] NOTICE ", "" ],
	"error" => [ "[flail] ERROR ", "" ],
	"debug" => [ "[flail] DEBUG ", "" ],
);

has "eol" => (is => "rw", isa => "Str", default => "\n");
has "sep" => (is => "rw", isa => "Str", default => " ");
has "stream" => (is => "ro", isa => "Object", required => 1);
has "debug" => (is => "rw", isa => "Bool", default =>$ENV{"TEST_VERBOSE"}?1:0);
has "input" => (is => "ro", isa => "Maybe[Object]");
has "line_no" => (is => "rw", isa => "Int", default => 0);
has "width" => (is => "rw", isa => "Int", default => 0);
has "height" => (is => "rw", isa => "Int", default => 0);
has "col_no" => (is => "rw", isa => "Int", default => 0);

sub reset_line	{ $_[0]->line_no(0); $_[0]->col_no(0); $_[0] }
sub is_full	{ $_[0]->height && ($_[0]->line_no >= $_[0]->height-2) }

sub inc_line {
	my($self,$chars) = @_;
	my $inc = 1;
	$inc += int(($chars + $self->col_no) / $self->width) if $self->width;
	$self->line_no($inc + $self->line_no);
	$self->col_no(0);
	return $self;
}

sub BUILD {
	my($self,$params) = @_;
	$self->stream->autoflush(1);
	my($w,$h) = screen_columns();
	$self->width($w);
	$self->height($h);
}

sub Default {
	$DEFAULT_SINK ||=
	    shift->new(
		    stream => IO::Handle->new_from_fd(fileno(STDOUT),"w"),
		    input => IO::Handle->new_from_fd(fileno(STDIN),"r"),
	    );
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
	return $self->leader($style) .
	    join($self->sep, map { msgfy $_ } @msg) .
	    $self->trailer($style);
}

sub writeln {
	my($self,@msg) = @_;
	my $str = $self->msg_to_string(@msg);
	return unless defined $str;
	$str .= $self->eol if $self->eol && substr($str,-1,1) ne $self->eol;
	$self->stream->write($str);
	$self->inc_line(length($str)-1);
	return $self;
}

sub write {
	my($self,$str) = @_;
	return unless defined $str;
	$str =~ s/\s*$//gs;
	$self->stream->write($str);
	$self->col_no(length($str) + $self->col_no);
	return $self;
}

sub newline {
	my($self) = @_;
	$self->stream->write($self->eol);
	$self->inc_line(0);
	return $self;
}

sub emit {
	my($self,@args) = @_;
	my %argos = (@args == 1) ? ("line" => $args[0]) : @args;
	my $ret = undef;
	if (exists($argos{"page_start"})) {
		$ret = $self->writeln("PAGE_START","$argos{page_start}");
	} elsif (exists($argos{"page_end"})) {
		$ret = $self->writeln("PAGE_END","$argos{page_end}");
	} elsif (exists($argos{"row"})) {
		$ret = $self->writeln("ROW","$argos{row}");
	} else {
		$ret = $self->writeln(@args);
	}
	return $ret;
}

sub more {
	my($self,$pageable) = @_;
	$self->write("--MORE ${pageable}--");
	my $resp = $self->input->getline;
	return undef unless defined $resp;
	$resp = clean($resp);
	$self->reset_line();
	return affirmative($resp) ?
	    $self->emit(page_start => $pageable) : undef;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
