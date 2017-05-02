#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::Message - An email message

=head1 SYNOPSIS

  use Flail::Message;
  blah;

=head1 DESCRIPTION

A proxy for a mail message that behaves the same in the privsep child
and the parent process even though the data it holds comes from
different sources.

=cut

package Flail::Message;
use Modern::Perl;
use Moose;
use Flail::Util qw(ts dumpola udstr);
use vars qw($SUMMARY_SEP @SUMMARY_FIELDS @MESSAGE_FIELDS %FIELD_XFORMS);
use overload '""' => \&to_string;

$SUMMARY_SEP = "|";
@SUMMARY_FIELDS = qw(timestamp from subject);
%FIELD_XFORMS = (
	"timestamp" => \&ts,
	"from" => sub { $_[0] ? $_[0]->unfoldedBody : undef },
	"to" => sub { $_[0] ? $_[0]->unfoldedBody : undef },
	"cc" => sub { $_[0] ? $_[0]->unfoldedBody : undef },
    );
@MESSAGE_FIELDS = qw(subject messageId from to cc body contentType);

has "real" => (
	is => "rw", isa => "Maybe[Mail::Message]");
#	handles => [@MESSAGE_FIELDS]);
has "timestamp" => (is => "rw", isa => "Maybe[Int]");
has "from" => (is => "rw", isa => "Maybe[Str]");
has "to" => (is => "rw", isa => "Maybe[Str]");
has "cc" => (is => "rw", isa => "Maybe[Str]");
has "subject" => (is => "rw", isa => "Maybe[Str]");
has "messageId" => (is => "rw", isa => "Maybe[Str]");
has "contentType" => (is => "rw", isa => "Maybe[Str]");
has "body" => (is => "rw", isa => "Maybe[ArrayRef[Str]]");

sub BUILD {
	my($self,$params) = @_;
	if ($self->real) {
		# in the child
		warn("$$ $self decoding the real message: ".$self->real."\n");

		$self->messageId("".$self->real->messageId);

		my $head = $self->real->head;
		my $body = $self->real->decoded;

		foreach my $field (@MESSAGE_FIELDS) {
			if ($field eq "body" ) {
				my $aref = $body->lines();
				$self->body($aref);
				warn("$$ decoded body w/".
				     scalar(@$aref)." lines\n");
			} elsif ($field eq "contentType") {
				my $mtype = $body->mimeType;
				$self->contentType("$mtype");
				warn("$$ decoded contentType = $mtype\n");
			} elsif ($field ne "messageId") {
				my $xf = $FIELD_XFORMS{$field};
				my $raw = $head->get($field);
				my $cooked = $xf ? &$xf($raw) : udstr($raw);
				$self->$field($cooked);
			}
		}
	} else {
		my @missing = grep {!exists($params->{$_})} @MESSAGE_FIELDS;
		warn(ref($self)." constructor invoked missing: @missing")
		    if @missing;
	}
}

# the opposite of bless: marshal for RPC result or whatever
sub curse {
	my($self) = @_;
	my $c = { map { $_ => $self->$_ } @MESSAGE_FIELDS };
#	warn("Flail::Message::curse => ".dumpola($c)."\n");
	return $c;
}

sub to_string {
	my($self) = @_;
	join($SUMMARY_SEP, map { udstr($self->$_) } @SUMMARY_FIELDS);
}

# to mung args on their way to the constructor:
around BUILDARGS => sub {
	my $orig = shift;
	my $class = shift;
	my $args;
	if (@_ == 1 && ref($_[0]) eq 'HASH') {
		$args = shift;
	} elsif (@_ == 1) {
		$args = { "real" => shift };
	} else {
		$args = { @_ };
	}
	return $args;
};

__PACKAGE__->meta->make_immutable;

1;

__END__
