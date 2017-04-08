#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::MessageSet - brief description

=head1 SYNOPSIS

  use Flail::MessageSet;
  blah;

=head1 DESCRIPTION

Describe the module with real words.


=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Flail::MessageSet;
use Moose;
use Flail::MessageSet::Maildir;
use Flail::Util qw(dumpola test_warn);
use overload '""' => sub { "" . shift->real };

has "query" => (is => "rw", isa => "Maybe[Str]");
has "folder" => (is => "rw", isa => "Maybe[Str]");
has "privsep_child" => (is => "rw", isa => "Maybe[Flail::ChildProcess]");
has "real" => (is => "rw", isa => "Maybe[Flail::MessageSet::Handler]");
#	handles => [qw[count this finish first final next prev is_exhausted]]);

sub _dispatch {
	my($self,$name,@args) = @_;
	# real is undef in the parent
	return $self->real ?
	    $self->real->$name : $self->privsep_child->req($self,$name,@args);
}

sub _handle {
}

sub count	{ shift->_dispatch("count",@_) }
sub this	{ shift->_dispatch("this",@_) }
sub finish	{ shift->_dispatch("finish",@_) }
sub first	{ shift->_dispatch("first",@_) }
sub final	{ shift->_dispatch("final",@_) }
sub next	{ shift->_dispatch("next",@_) }
sub prev	{ shift->_dispatch("prev",@_) }
sub is_exhausted{ shift->_dispatch("is_exhausted",@_) }

sub BUILD {
	my($self,$params) = @_;
	my $child = Flail::ChildProcess->new(
		"app" => $params->{"app"},
		"name" => "maildir reader",
		"pledge" => "rpath",
		"handler" => sub { $self->_handle(@_) },
	    );
	$self->privsep_child($child);
}

sub run {
	my($self) = @_;
	return $self if $self->privsep_child->pid;
	$self->privsep_child->loop($self);
}

sub Query { shift->new(@_)->run() }

__PACKAGE__->meta->make_immutable;

1;

__END__
