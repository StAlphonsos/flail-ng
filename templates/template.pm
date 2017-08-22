#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::module - brief description

=head1 SYNOPSIS

  use Flail::module;
  blah;

=head1 DESCRIPTION

Describe the module with real words.

=cut

package Flail::module;
use Modern::Perl;
use Moose;

extends "Flail::Reporter";

__PACKAGE__->meta->make_immutable;

1;

__END__
