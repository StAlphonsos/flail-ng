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
use Flail::Util qw(ts);
use vars qw($SUMMARY_SEP @SUMMARY_FIELDS @MESSAGE_FIELDS %FIELD_XFORMS);
use overload '""' => \&to_string;

$SUMMARY_SEP = "|";
@SUMMARY_FIELDS = qw(timestamp from subject);
%FIELD_XFORMS = (
	"timestamp" => \&ts,
	"from" => sub { $_[0] ? $_[0]->format : "?from?" },
	"to" => sub { $_[0] ? $_[0]->format : "?to?" },
	"cc" => sub { $_[0] ? $_[0]->format : "?cc?" },
    );
@MESSAGE_FIELDS = qw(subject messageId from to cc body contentType);

has "real" => (
	is => "rw", isa => "Maybe[Mail::Message]");
#	handles => [@MESSAGE_FIELDS]);
has "timestamp" => (is => "rw", isa => "Maybe[Int]");
has "from" => (is => "rw", isa => "Maybe[Mail::Address]");
has "to" => (is => "rw", isa => "Maybe[Mail::Address]");
has "cc" => (is => "rw", isa => "Maybe[Mail::Address]");
has "subject" => (is => "rw", isa => "Maybe[Str]");
has "messageId" => (is => "rw", isa => "Maybe[Str]");
has "contentType" => (is => "rw", isa => "Maybe[Str]");
has "body" => (is => "rw", isa => "Maybe[Mail::Message::Body]");

sub BUILD {
	my($self,$params) = @_;
	if ($self->real) {
		foreach my $field (@MESSAGE_FIELDS) {
			# there's a decode step here maybe...? XXX
			$self->$field($self->real->$field);
		}
	} else {
		my @missing = grep {!exists($params->{$_})} @MESSAGE_FIELDS;
		warn(ref($self)." constructor invoked missing: @missing");
	}
}

# the opposite of bless: marshal for RPC result or whatever
sub curse {
	my($self) = @_;
	return { map { $_ => $self->format_field($_) } @MESSAGE_FIELDS };
}

sub format_field {
	my($self,$name) = @_;
	my $xform = $FIELD_XFORMS{$name};
	my($val) = $self->$name;
	return $xform ? &$xform($val) : $val;
}

sub to_string {
	my($self) = @_;
	join($SUMMARY_SEP,
	     map { sprintf("%s", $self->format_field($_)) } @SUMMARY_FIELDS);
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
