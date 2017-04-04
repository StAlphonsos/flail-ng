#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::MessageSet::Handler - base class for message set handlers

=head1 SYNOPSIS

  # base class, inherit from it

=head1 DESCRIPTION

I guess this is really a role...?

=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Flail::MessageSet::Handler;
use Moose;
use Flail::Message;
use overload '""' => sub { sprintf("<%s: %d msgs>",ref($_[0]),$_[0]->count) };

has "idx" => (is => "rw", isa => "Int", default => 0);
has "msg_class" => (is => "rw", isa => "Str", default => "Flail::Message");

sub finish	{ 1; }
sub this	{ die "implement this" }
sub count	{ die "implement count" }

sub a_msg	{ shift->msg_class->new(@_) }
sub is_exhausted{ 1+$_[0]->idx >= $_[0]->count }

sub msg_at {
	my($self,$off) = @_;
	my $raw = $self->this($off);
	return undef unless $raw;
	return $self->msg_class->new($raw);
}

sub first {
	my($self) = @_;
	$self->idx(0);
	return $self->msg_at(0);
}

sub final {
	my($self) = @_;
	my $x = $self->count - 1;
	$x = 0 if $x < 0;
	$self->idx($x);
	return $self->msg_at(0);
}

sub next {
	my $self = shift(@_);
	my $r = $self->msg_at(1);
	$self->idx(1+$self->idx) if defined $r;
	return $r;
}

sub prev {
	my $self = shift(@_);
	return undef unless $self->idx > 0;
	my $r = $self->msg_at(-1);
	$self->idx($self->idx-1);
	return $r;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
