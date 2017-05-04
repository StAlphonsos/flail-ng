#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::Reporter - base class for Flail objects

=head1 SYNOPSIS

  use Flail::Reporter;
  blah;

=head1 DESCRIPTION

Modeled on L<Mail::Reporter>, this class serves as a base class
for most Flail classes.  Its main job is to implement sane logging.

=cut

package Flail::Reporter;
use Modern::Perl;
use Moose;
use vars qw(%LOG_LEVELS);

%LOG_LEVELS = (
	"debug" => [ 9, "#" ],
	"info" => [ 8, "*" ],
	"notice" => [ 7, ":" ],
	"warning" => [ 6, "%" ]
	"error" => [ 5, "!" ],
	"fatal" =>  [ 4, "." ],
);

sub _spew	{ warn(@_) }

has "_log_level" => (is => "rw", isa => "Str", default => "error");
has "_real_logger" => (is => "rw", isa => "CodeRef", default => \&_spew);

sub log {
	my $self = shift;
	if (!@_) {
		&{$self->_real_logger}("empty message");
		return;
	}
	my($msg,@xtra) = @_;

}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut
