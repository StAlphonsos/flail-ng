#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::ChildProcess - OO interface to privsep

=head1 SYNOPSIS

  use POSIX qw(_exit);

  # given some $obj that implements a method called "rpc_methods"
  # which returns a hashref whose keys are allowable methods to
  # invoke via RPC:
  my $child = Flail::ChildProcess->new(
                 obj => $obj,
                 name => "maildir reader",
                 promises => "rpath stdio");
  # drop into the RPC service loop in the child process:
  _exit($child->loop) if $child->in_child;

  # in the parent, to invoke a method on $obj in the child:
  my @results = $child->req("a_method",$args...);

  # ... when done, kill and reap the child:
  $child->finish();

=head1 DESCRIPTION

This class implements a framework for doing privilege separation in
Perl using Moose.

=head1 INTERFACE

=cut

package Flail::ChildProcess;
use Modern::Perl;
use Socket;
use IO::Handle;
use Moose;
use Try::Tiny;
use JSON qw(encode_json decode_json);
use OpenBSD::Pledge;			# for now only one sandbox
use Flail::App;
use Flail::Util qw(curse defkey hexdump dumpola udstr sandbox_violation);
use constant {
	RPC_OK => 0,
	RPC_ERR_BAD_METHOD => 1,
	RPC_ERR_BAD_ARGS => 2,
	RPC_ERR_DECODE_ARGS => 3,
	RPC_ERR_INVOKE => 4,
	RPC_ERR_ENCODE_RESULT => 5,
	RPC_ERR_DECODE_RESULT => 6,
};
use overload '""' => sub {
	sprintf("<ChildProcess pid %s>",$_[0]->pid?$_[0]->pid:"$$");
};

has "app" => (is => "rw", isa => "Maybe[Flail::App]");
has "name" => (is => "rw", isa => "Str");
has "promises" => (is => "rw", isa => "Str");
has "pid" => (is => "rw", isa => "Maybe[Int]");
has "run" => (is => "rw", isa => "CodeRef");
has "timeout" => (is => "rw", isa => "Int", default => 1);
has "buf" => (is => "rw", isa => "Maybe[Str]", default => "");
has "bufsiz" => (is => "rw", isa => "Int", default => 1024);
has "max_bufsiz" => (is => "rw", isa => "Int", default => 102400);
has "stream" => (is => "rw", isa => "Maybe[Object]");
has "inbuf" => (is => "rw", isa => "Str", default => "");
has "obj" => (is => "rw", isa => "Object");

# set up plumbing, fork child, do some bookkeeping
sub BUILD {
	my($self,$params) = @_;
	die "require an obj that can rpc_methods: ".$self->obj
	    unless $self->obj->can("rpc_methods");
	socketpair(CHILD, PARENT, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or
	    die "socketpair: $!";
	if (my $pid = fork()) {
		# parent process
		close(PARENT);
		$self->pid($pid);
		$self->stream(IO::Handle->new_from_fd(fileno(CHILD),"r+"));
		$self->stream->autoflush(1);
		$self->app->register_child($self) if $self->app;
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
sub in_parent	{ shift->pid ? 1 : 0 }

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
	my($self,$buf) = @_;
	my $buf_len = length($buf);
	my $buf_off = 0;
	my $nw = $self->stream->syswrite($buf,$buf_len);
	die("syswrite($buf_len) failed nw=$nw: $!") if $nw <= 0;
	$buf_off = $nw;
	while ($buf_off < $buf_len) {
		$nw = $self->stream->syswrite($buf,$buf_len,$buf_off);
		die("syswrite($buf_len,$buf_off) failed nw=$nw: $!")
		    if $nw <= 0;
		$buf_off += $nw;
	}
}

# counted write - prefix $buf with a count and send it all via awrite()
sub cwrite {
	my($self,$buf) = @_;
	my $buflen = length($buf);
	my $head = pack("w",$buflen);
	$self->awrite($head . $buf);
}

# counted read - read a count followed by that many bytes or die
sub cread {
	my($self) = @_;
	my $tout = $self->timeout;
	my $buf = $self->buf;
	my $nbuf = length($buf);
	my $bufsiz = $self->bufsiz;
	my $max_bufsiz = $self->max_bufsiz;
	if ($bufsiz <= $nbuf) {
		$bufsiz *= 2;
		$self->bufsiz($bufsiz);
	}
	warn("$$ top cread bufsiz=$bufsiz nbuf=$nbuf\n");
	my $n = $self->stream->sysread($buf,$bufsiz,$nbuf);
	my $done = 0;
	while (defined($n)) {
		my $nbuf;

		die("$$ sysread returned $n: $!") if $n < 0;

		if ($n == 0) {
			warn("$$ read nothing, timeout=$tout ...\n");
			sleep($tout);
			goto READ_MORE;
		}

		# try to decode a count and at least that many bytes from $buf
		try {
			warn("$$ trying to unpack count\n");
			my($count,$rest) = unpack("w a*",$buf);
			warn("$$ after unpack count=".udstr($count).
			     " w/".length($rest?$rest:"")." bytes\n");

			goto READ_MORE unless defined $count;

			if (!$count) {
				warn("$$ got a zero count, dropping out\n");
				$buf = undef;
				$done = 1;
			} else {
				$nbuf = length($rest);
				if ($nbuf >= $count) {
					warn("$$ cread wins! nbuf=$nbuf\n");
					$self->buf($rest);
					$buf = $rest;
					$done = 1;
				} else {
					# else need to read more
					warn("$$ short cread nbuf=$nbuf ".
					     "count=$count\n");
					if ($count >= $bufsiz) {
						$bufsiz = $count + 128;
						$self->bufsiz($bufsiz);
					}
				}
			}
		} catch {
			warn("decode of count failed? @_\n");
		};
		last if $done;

	      READ_MORE:
		$nbuf = length($buf);
		if ($nbuf + 128 >= $bufsiz) {
			if ($bufsiz >= $max_bufsiz) {
				warn("max bufsiz $max_bufsiz reached!");
				last;
			}
			$bufsiz += 128;
			$self->bufsiz($bufsiz);
		}
		warn("$$ bot cread bufsiz=$bufsiz nbuf=$nbuf\n");
		$n = $self->stream->sysread($buf,$bufsiz,$nbuf);
	}
	warn("$$ cread => ".length($buf)." bytes\n");
	return $buf;
}

=pod

=over 4

=item * loop

Drop into a synchronous RPC service loop in the child process, based
on the object given to our constructor in the C<obj> parameter.  We
invoke the C<rpc_methods> method on the object at startup, which we
expect will return a hashref whose keys are allowable methods to
invoke via RPC in the child.  If an invalid method is received we
return an error without interpreting the arguments to the invocation.

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
	my($self) = @_;
	my $obj = $self->obj;
	my $methods = $obj->rpc_methods;
	my $exit_code = 0;
	warn("$$ child RPC methods: ".join(", ", sort keys %$methods)."\n");
	while (1) {
		my $buf = $self->cread();
		warn("$$ child cread returned ".length($buf)." bytes\n");

		if (!defined($buf)) {
			warn("$$ cread failed, dropping out of loop\n");
			$exit_code = 1;
			last;
		}

		my($meth,$args,$args_s,$rest,$err,@results,$result_s);

		# try unpacking the message, if it fails keep reading
		try {
			($meth,$args_s,$rest) = unpack("w/a* w/a* a*", $buf);
		} catch {
			warn("$$ unpack ".length($buf)." bytes: @_\n");
			next;
		};

		# message unpacked fine, check it for sanity
		warn("$$ child got method |$meth| args_s=|$args_s|\n");

		# the special "quit" message:
		last if $meth eq ".";

		$self->buf($rest);

		# invalid method invoked
		if (!exists($methods->{$meth})) {
			warn("$$ child bad method: |$meth|\n");
			$err = RPC_ERR_BAD_METHOD;
			$result_s = _errs("invalid method: $meth");
			goto SEND_RESP;
		}

		# method looks good, now decode the arguments
		try {
			$args = decode_json($args_s);
			if (ref($args) ne "ARRAY") {
				warn("$$ child bad args: |$args_s|\n");
				$err = RPC_ERR_BAD_ARGS;
				$result_s = _errs("args not decode to array");
				goto SEND_RESP;
			}
		} catch {
			warn("$$ child unparseable args: |$args_s|\n");
			$err = RPC_ERR_DECODE_ARGS;
			$result_s = _errs("could not decode args as JSON: @_");
			goto SEND_RESP;
		};

		# finally, do the deed
		try {
			warn("$$ child invoking $meth(@$args) on $obj\n");
			@results = $obj->$meth(@$args);
			warn("$$ child got ".scalar(@results).
			     " results: @results\n");
		} catch {
			warn("$$ child error invoking $meth: @_\n");
			$err = RPC_ERR_INVOKE;
			$result_s = _errs("invoking $meth: @_");
			goto SEND_RESP;
		};

		# if we get here there are results to encode
		try {
			$err = RPC_OK;
			$result_s = encode_json(curse(\@results));
		} catch {
			$err = RPC_ERR_ENCODE_RESULT;
			$result_s = _errs("could not encode JSON result: @_");
		};

	      SEND_RESP: # send $err,$result_s to other side
		my $result_sz = length($result_s);
		warn("$$ child sending back err=$err result_sz=$result_sz\n");
		my $resp = pack("w w/a*",$err,$result_s);
		$self->cwrite($resp);
	}

	$self->stream->close();

	warn("$$ child dropped out of loop, returning exit code $exit_code\n");
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
	my($err,$resp_s,$rest,$result);
	my $args_s = encode_json(\@args);
	my $req = pack("w/a* w/a*", $name, $args_s);
	$self->cwrite($req);
	my $buf = $self->cread();
	($err,$resp_s,$rest) = unpack("w w/a* a*", $buf);
	my $nbuf = length($rest);
	warn("$nbuf leftovers remain: |".hexdump($rest)."|\n") if $nbuf;
	$self->buf($rest);
	die _rpc_errs($err,$resp_s) unless $err == RPC_OK;

	try {
		$result = decode_json($resp_s);
		die _rpc_errs(RPC_ERR_DECODE_RESULT,
			      "results not an array $resp_s: @_")
		    if ref($result) ne "ARRAY";
	} catch {
		die _rpc_errs(RPC_ERR_DECODE_RESULT,
			      "cannot decode JSON result: @_");
	};

	# an rpc method can be assocated with a coderef to swizzle
	# return values into something (a blessed ref, probably)
	if (defined(my $swiz = $self->obj->rpc_methods->{$name})) {
		my @swizzled = &$swiz(@$result);
		$result = \@swizzled;
	}

	return @$result if wantarray;
	return $result->[0];
}

=pod

=over 4

=item * shutdown

Invoked in the parent to tell the child process to shut down cleanly.
Should only be followed by C<finish>.

=item * finish do_wait => 0|1, signo => $sig, coredump => 0|1, xit => $exit

Send the child process a special message to drop out of its RPC loop
(the C<loop> method) and die.  By default C<do_wait> is true and we
invoke L<waitpid> to reap the child process; if we are invoked in a
context where this has already happened, e.g. a C<$SIG{CHLD}> handler,
then C<do_wait> should be specified as zero and C<signo>, C<coredump>
and C<xit> should be passed, since the caller is where C<$?> was
interpreted.

In the default case, where C<do_wait> is true, we first invoke
C<shutdown> to tell the child to exit the C<loop> method and clean up.
In the case where C<do_wait> is false we assume this has already
happened, or that the child died for some other reason (like a
coredump).

=back

=cut

sub shutdown {
	my($self) = @_;
	$self->cwrite(pack("w/a* w/a*",".","[]"));
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
		$self->app->unregister_child($pid) if $self->app;
	}

	$self->stream->close();
	$self->stream(undef);

	if ($coredump) {
		warn("$$ child $pid dumped core! signal $signo, exit $xit\n");
	} elsif (sandbox_violation($pid,$signo,$coredump,$xit)) {
		warn("$$ child $pid aborted due to pledge violtaion\n");
	} elsif ($do_wait) {
		warn("$$ child $pid reaped, signal $signo, exit $xit\n");
	} # else whatever called us will do something with the information

	return $xit;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
