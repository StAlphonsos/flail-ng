#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::ChildProcess - OO interface to privsep

=head1 SYNOPSIS

  # given some $obj that implements a method called "rpc_methods"
  # which returns a hashref whose keys are allowable methods to
  # invoke via RPC:
  my $child = Flail::ChildProcess->new(
                 name => "maildir reader",
                 promises => "rpath stdio");
  if ($child->in_child) {
    # initialize whatever in $obj in the child, then drop into loop
    exit($child->loop($obj));
  }

  # in the parent, to invoke a method in the child:
  my @results = $child->req("a_method",$args...);

  # ... when done, kill and reap the child:
  $child->finish();

=head1 DESCRIPTION

This class implements a framework for doing privilege separation in
Perl using Moose.

=head1 INTERFACE

=cut

package Flail::ChildProcess;
use Socket;
use IO::Handle;
use Moose;
use Try::Tiny;
use JSON qw(encode_json decode_json);
use OpenBSD::Pledge;
use Flail::App;
use Flail::Util qw(curse defkey hexdump);
use constant {
	RPC_OK => 0,
	RPC_ERR_BAD_METHOD => 1,
	RPC_ERR_BAD_ARGS => 2,
	RPC_ERR_DECODE_ARGS => 3,
	RPC_ERR_INVOKE => 4,
	RPC_ERR_ENCODE_RESULT => 5,
	RPC_ERR_DECODE_RESULT => 6,
};

has "app" => (is => "rw", isa => "Maybe[Flail::App]");
has "name" => (is => "rw", isa => "Str");
has "promises" => (is => "rw", isa => "Str");
has "pid" => (is => "rw", isa => "Maybe[Int]");
has "run" => (is => "rw", isa => "CodeRef");
has "timeout" => (is => "rw", isa => "Int", default => 1);
has "bufsiz" => (is => "rw", isa => "Int", default => 1024);
has "max_bufsiz" => (is => "rw", isa => "Int", default => 10240);
has "stream" => (is => "rw", isa => "Maybe[Object]");
has "inbuf" => (is => "rw", isa => "Str", default => "");

# set up plumbing, fork child, do some bookkeeping
sub BUILD {
	my($self,$params) = @_;
	socketpair(CHILD, PARENT, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or
	    die "socketpair: $!";
	if (my $pid = fork()) {
		# parent process
		close(PARENT);
		$self->pid($pid);
		$self->stream(IO::Handle->new_from_fd(fileno(CHILD),"r+"));
		$self->stream->autoflush(1);
#		$self->app->register_child($self) if $self->app;
	} else {
		# child process
		$0 = "[flail] ".$self->name;
		close(CHILD);
		$self->stream(IO::Handle->new_from_fd(fileno(PARENT),"r+"));
		$self->stream->autoflush(1);
		# XXX stderr
		# XXX drop privs
		# XXX chroot if poss
		pledge(split(/\s+/,$self->promises));
	}
}


=pod

=over 4

=item * in_child

Returns true in child, false in parent.

=back

=cut

sub in_child	{ shift->pid ? 0 : 1 }

sub _errs {
	my($errstr) = @_;
	$errstr =~ s,",\\",gs;
	return sprintf(q{["%s"]}, $errstr);
}

sub _rpc_errs {
	my($err,$resp_s) = @_;
	return "*** RPC error $err: $resp_s";
}

# atomic write
sub awrite {
	my($self,$resp) = @_;
	my $resp_len = length($resp);
	my $resp_off = 0;
	my $nw = $self->stream->syswrite($resp,$resp_len);
	die("syswrite($resp_len) failed nw=$nw: $!") if $nw <= 0;
	$resp_off = $nw;
	while ($resp_off < $resp_len) {
		$nw = $self->stream->syswrite(
			$resp,$resp_len,$resp_off);
		die("syswrite($resp_len,$resp_off) failed nw=$nw: $!")
		    if $nw <= 0;
		$resp_off += $nw;
	}
}


=pod

=over 4

=item * loop $obj

Drop into a synchronous RPC service loop in the child process, based
on the given object.  We invoke the C<rpc_methods> method on the
object at startup, which we expect will return a hashref whose keys
are allowable methods to invoke via RPC in the child.  If an invalid
method is received we return an error without interpreting the
arguments to the invocation.

RPC requests are generated for the child using the C<req> method in
the parent process.  In the child the C<loop> method receives and
parses requests, invokes the real method on the C<$obj> in the child
process and returns the results across the RPC channel to the parent
process.  Blessed references should not be returned by any of the
RPC-invokable methods, or if they are then they should speak the
C<curse> protocol by implementing a method named C<curse> that returns
an unblessed reference containing data that we wish to return to an
invoker in the parent process.

The idea behind this pattern is that e.g. code that decodes data that
we wish to happen in a sandboxed environment runs in the child
process.  It does its work, using reduced privileges and capabilities,
and if successful returns parsed data in a neutral form to the parent.

=back

=cut

sub loop {
	my($self,$obj) = @_;
	my $buf = "";
	my $nbuf = 0;
	my $len = 0;
	my $bufsiz = 1024;
	my $max_bufsiz = $self->max_bufsiz;
	my $n = $self->stream->sysread($buf,$bufsiz);
	my $methods = $obj->rpc_methods;
	my $exit_code = 0;
	while (defined($n)) {
		my($meth,$args,$args_s,$rest,$err,$result,$result_s);

		if ($n == 0) {
			warn("$$ read nothing, timeout=$self->timeout ...\n");
			sleep($self->timeout);
			goto READ_MORE;
		}
		$nbuf += $n;

		# try unpacking the message, if it fails keep reading
		try {
			($meth,$args_s,$rest) = unpack("w/a* w/a* a*", $buf);
		} catch {
			warn("$$ unpack ".length($buf)." bytes: @_\n");
			goto READ_MORE;
		};

		# message unpacked fine, check it for sanity

		# the special "quit" message:
		last if $meth eq ".";

		$buf = $rest ? $rest : "";
		$nbuf = length($buf);

		# invalid method invoked
		if (!exists($methods->{$meth})) {
			$err = RPC_ERR_BAD_METHOD;
			$result_s = _errs("invalid method: $meth");
			goto SEND_RESP;
		}

		# method looks good, now decode the arguments
		try {
			$args = decode_json($args_s);
			if (ref($args) ne "ARRAY") {
				$err = RPC_ERR_BAD_ARGS;
				$result_s = _errs("args not decode to array");
				goto SEND_RESP;
			}
		} catch {
			$err = RPC_ERR_DECODE_ARGS;
			$result_s = _errs("could not decode args as JSON: @_");
			goto SEND_RESP;
		};

		# finally, do the deed
		try {
			$result = $obj->$meth(@$args);
		} catch {
			$err = RPC_ERR_INVOKE;
			$result_s = _errs("invoking $meth: @_");
			goto SEND_RESP;
		};

		# if we get here there are results to encode
		try {
			$err = RPC_OK;
			$result_s = encode_json([curse($result)]);
		} catch {
			$err = RPC_ERR_ENCODE_RESULT;
			$result_s = _errs("could not encode JSON result: @_");
		};

	      SEND_RESP: # send $err,$result_s to other side
		my $resp = pack("w w/a*",$err,$result_s);
		$self->awrite($resp);

	      READ_MORE:
		if ($nbuf + 16 >= $bufsiz) {
			if ($bufsiz >= $max_bufsiz) {
				warn("max bufsiz $max_bufsiz reached!");
				$exit_code = 1;
				last;
			}
			$bufsiz = $nbuf + 128;
		}
		$n = $self->stream->sysread($buf,$bufsiz,$nbuf);
	}
	$self->stream->close();
	return $exit_code;
}

=pod

=over 4

=item * req $name, @args...

Called in the parent process to invoke a method in the child.
The method named C<$name> is invoked with C<@args> as arguments.

=back

=cut

sub req {
	my($self,$name,@args) = @_;

	my $args_s = encode_json(\@args);
	my $req = pack("w/a* w/a*", $name, $args_s);
	$self->awrite($req);

	my $buf = "";
	my $nbuf = 0;
	my $bufsiz = $self->bufsiz;
	my $max_bufsiz = $self->max_bufsiz;
	my $n = $self->stream->sysread($buf,$bufsiz,$nbuf);

	my $trips = 0;

	while (defined($n)) {
		my($err,$resp_s,$rest,$result);

		if ($n == 0) {
			warn("$$ read nothing, timeout=$self->timeout ...\n");
			sleep($self->timeout);
			++$trips;
			goto READ_MORE;
		}
		try {
			($err,$resp_s,$rest) = unpack("w w/a* a*", $buf);
			warn("$$ req $name (@args) => #$err |$resp_s|\n");
		} catch {
			goto READ_MORE;
		};

		$buf = $rest ? $rest : "";
		$nbuf = length($buf);

		warn("$nbuf leftovers remain: |".hexdump($buf)."|\n") if $nbuf;
		die _rpc_errs($err,$resp_s) unless $err == RPC_OK;

		try {
			$result = decode_json($resp_s);
			die _rpc_errs(RPC_ERR_DECODE_RESULT,
				      "results not an array $resp_s: @_")
			    if ref($result) ne "ARRAY";
		} catch {
			die _rpc_errs(RPC_ERR_DECODE_RESULT,
				      "cannot decode JSON result $resp_s: @_");
		};

		return @$result;

	      READ_MORE:
		if ($nbuf + 16 >= $bufsiz) {
			if ($bufsiz >= $max_bufsiz) {
				warn("max bufsiz $max_bufsiz reached!");
				last;
			}
			$bufsiz = $nbuf + 128;
			$self->bufsiz($bufsiz);
		}
		$n = $self->stream->sysread($buf,$bufsiz,$nbuf);
	}
}

=pod

=over 4

=item * shutdown

Invoked in the parent to tell the child process to shut down cleanly.
Should only be followed by C<finish>.

=item * finish do_wait => 0|1, signo => $sig, coredump => 0|1, xit => $exit

Send the child process a special message to drop out of its RPC loop
(the C<loop> method) and die.  

=back

=cut

sub shutdown {
	my($self) = @_;
	$self->awrite(pack("w/a* w/a*",".","[]"));
	$self->stream->close();
	$self->stream(undef);
	return $self;
}

sub finish {
	my($self,%params) = @_;
	return unless $self->pid;

	my $paref = \%params;
	my $do_wait = defkey($paref,"do_wait",1);
	my $signo = defkey($paref,"signo",0);
	my $coredump = defkey($paref,"coredump",0);
	my $xit = defkey($paref,"xit",0);

	my $pid = $self->pid;

	if ($do_wait) {
		$self->shutdown();
		$pid = waitpid($pid, 0);
		($signo,$coredump,$xit) = ($? & 127,$? & 128,$? >> 8);
	}

	if ($coredump) {
		warn("child $pid dumped core! signal $signo, exit $xit\n");
	} elsif ($do_wait) {
		warn("child $pid reaped, signal $signo, exit $xit\n");
	} # else whatever called us will do something with the information

	return $xit;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
