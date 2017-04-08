#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::ChildProcess - brief description

=head1 SYNOPSIS

  use Flail::ChildProcess;
  blah;

=head1 DESCRIPTION

Describe the module with real words.


=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Flail::ChildProcess;
use Moose;
use OpenBSD::Pledge;
use Flail::App;

has "app" => (is => "rw", isa => "Flail::App");
has "name" => (is => "rw", isa => "Str");
has "pledge" => (is => "rw", isa => "Str");
has "pid" => (is => "rw", isa => "Maybe[Int]");
has "run" => (is => "rw", isa => "CodeRef");

sub BUILD {
	my($self,$params) = @_;
	socketpair(CHILD, PARENT, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or
	    die "socketpair: $!";
	if (my $pid = fork()) {
		close(PARENT);
		$self->pid($pid);
		$self->stream(IO::Handle->new_from_fd(fileno(CHILD),"r+"));
		$self->stream->autoflush(1);
		$self->app->register_child($self);
	} else {
		close(CHILD);
		$self->stream(IO::Handle->new_from_fd(fileno(PARENT),"r+"));
		$self->stream->autoflush(1);
		pledge(split(/\s+/,$self->pledge));
	}
}

sub loop {
	my($self,$obj) = @_;
}

sub pack_request {
	my($self,$obj,$name,@args) = @_;
}

sub send_framed {
	my($self,$req) = @_;
}

sub recv_response {
	my($self,$req) = @_;
}

sub unpack_response {
	my($self,$obj,$resp) = @_;
}

sub req {
	my($self,$obj,$name,@args) = @_;
	my $req = $self->pack_request($obj,$name,@args)
	    or die("packing error for $obj w/name=$name args=@args");
	$self->send_framed($req)
	    or die("send_framed failed w/req=$req");
	my $resp = $self->recv_response($req)
	    or die("recv_resp w/req=$req");
	return $self->unpack_response($obj,$resp);
}

__PACKAGE__->meta->make_immutable;

1;

__END__
