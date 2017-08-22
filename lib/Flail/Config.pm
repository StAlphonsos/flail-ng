#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::Config - configuration data for flail

=head1 SYNOPSIS

  print Flail::Config->Default->get("maildir");

=head1 DESCRIPTION

Describe the module with real words.

=cut

package Flail::Config;
use Modern::Perl;
use Moose;
use Flail::Util qw(basename_env dirname_env);
use vars qw($DEFAULT_CONF %DEFAULTS @MAILDIR_VARS);
@MAILDIR_VARS = qw(FLAIL_TEST_MAILDIR MAILDIR);

%DEFAULTS = (
	"maildir" => basename_env(@MAILDIR_VARS) || "Maildir",
	"maildir_base" => dirname_env(@MAILDIR_VARS) || $ENV{"HOME"}
);

extends "Flail::Reporter";

has "attrs" => (is => "rw", isa => "HashRef", default => sub { {} });
has "defaults" => (
	is => "rw", isa => "HashRef",
	default => sub { my $r = { %DEFAULTS }; $r; });
has "default_value" => (is => "rw", isa => "Str", default => "");

sub Default { $DEFAULT_CONF ||= shift->new; return $DEFAULT_CONF }

sub get {
	my($self,$name) = @_;
	return $self->attrs->{$name} if exists $self->attrs->{$name};
	return $self->defaults->{$name} if exists $self->defaults->{$name};
	return $self->default_value;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
