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

has "idx" => (is => "rw", isa => "Int", default => 0);

sub next	{ die "implement next" }
sub prev	{ die "implement prev" }
sub first	{ die "implement first" }
sub last	{ die "implement last" }
sub count	{ die "implement count" }

__PACKAGE__->meta->make_immutable;

1;

__END__
