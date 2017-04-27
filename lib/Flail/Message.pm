#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::Message - An email message

=head1 SYNOPSIS

  use Flail::Message;
  blah;

=head1 DESCRIPTION

Describe the module with real words.

=cut

package Flail::Message;
use Moose;
use Flail::Util qw(ts);
use vars qw($SUMMARY_SEP @SUMMARY_FIELDS @MESSAGE_METHODS %FIELD_XFORMS);
use overload '""' => \&to_string;

$SUMMARY_SEP = "|";
@SUMMARY_FIELDS = qw(timestamp from subject);
%FIELD_XFORMS = (
	"timestamp" => \&ts,
	"from" => sub { shift->format },
	"to" => sub { shift->format },
	"cc" => sub { shift->format },
    );
@MESSAGE_METHODS = qw(subject messageId from to cc body contentType);

has "real" => (
	is => "rw", isa => "Mail::Message", handles => [@MESSAGE_METHODS]);

# the opposite of bless: marshal for RPC result or whatever
sub curse {
	my($self) = @_;
	my $cursed = {
		class => ref($self),
		map { $_ => $self->format_field($_) } @MESSAGE_METHODS
	};
	return $cursed;
}

sub format_field {
	my($self,$name) = @_;
	my $xform = $FIELD_XFORMS{$name};
	my($val) = $self->real->$name;
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
