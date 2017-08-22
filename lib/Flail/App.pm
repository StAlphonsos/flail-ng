#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::App - top-level application object for flail

=head1 SYNOPSIS

  Flail::App->run;

=head1 DESCRIPTION

Blah.

=cut

package Flail::App;
use Moose;
use MooseX::NonMoose;
use App::Cmd::Setup -app;
use Flail::Sink;
use Flail::Config;
use Try::Tiny;
use POSIX ":sys_wait_h";

with "Flail::Reporter::Role";

has "sink" => (
	is => "rw", isa => "Flail::Sink", handles => [ qw[emit more] ]);
has "configuration" => (
	is => "rw", isa => "Flail::Config", handles => { 'conf' => 'get' });
has "children" => (is => "rw", isa => "HashRef", default => sub { {} });
has "_orig_chld" => (is => "rw", isa => "Any");

sub BUILD {
	my($self,$params) = @_;
	$self->sink(Flail::Sink->Default);
	$self->configuration(Flail::Config->Default);
}

sub DEMOLISH {
	my($self) = @_;
	if (my $n = scalar(keys(%{$self->children}))) {
		my $pids = join(", ", sort keys %{$self->children});
		$self->log("#DEMOLISHing w/$n child processes regd: $pids\n");
	}
}

# invoked from SIGCHLD to reap dead children.  if the children are
# known to us we invoke the finish method on their parental image
sub reaper {
	my($self) = @_;
	local($!,$?);
	$self->log("#$$ reaper invoked");
	while ((my $pid = waitpid(-1, WNOHANG)) > 0) {
		my($signo,$coredump,$xit) = ($? & 127,$? & 128,$? >> 8);
		$self->log("#$$ child $pid sig=$signo core=$coredump => $xit");
		my $kid = $self->children->{$pid};
		if ($kid) {
			$self->log("#$$ child $pid => $kid");
			try {
				$kid->finish(
					do_wait => 0,
					signo => $signo,
					coredump => $coredump,
					xit => $xit);
			} catch {
				$self->log("!reaping pid $pid: @_");
			};
			delete($self->children->{$pid});
		} elsif ($coredump) {
			$self->log("!$$ unknown child $pid dumped core! ".
				   "signal $signo, exit $xit");
		} else {
			$self->log("!$$ reaped unknown child $pid; ".
				   "signal $signo, exit $xit");
		}
	}
}

=pod

=over 4

=item * register_child $child

Should be called with a L<Flail::ChildProcess> instance so it can be
reaped by the application.  The reaper will attempt to invoke the
C<finish> method on the child like so:

    $kid->finish(
        do_wait => 0,
        signo => $signo,
        coredump => $coredump,
        xit => $xit);

Where the values of C<$signo>, C<$coredump> and C<$xit> are the signal
that terminated the child, whether or not it dumped core and the exit
status, respectively.

=back

=cut

sub register_child {
	my($self,$child) = @_;
	unless (scalar(keys(%{$self->children}))) {
		$self->_orig_chld($SIG{"CHLD"});
		$SIG{"CHLD"} = sub { $self->reaper() };
	}
	if (exists($self->children->{$child->pid})) {
		$self->log("!$$ tried to register known pid ".$child->pid.
		     ": $child");
	} else {
		$self->children->{$child->pid} = $child;
	}
	return $self;
}

=pod

=over 4

=item * unregister_child $child_or_pid

Undo the effects of C<register_child>: forget we know about a child
process, presumably because we've just reaped it.  If the last known
child process is unregistered we restore the original C<SIGCHLD>
signal handler as well.

=back

=cut

sub unregister_child {
	my($self,$child) = @_;
	my $pid = ref($child) ? $child->pid : $child;
	if (!exists($self->children->{$pid})) {
		$self->log("!$$ tried to unregister unknown pid $pid");
	} else {
		delete($self->children->{$pid});
		$SIG{"CHLD"} = $self->_orig_chld
		    unless scalar(keys(%{$self->children}));
	}
	return $self;
}

sub allow_any_unambiguous_abbrev { 1; }

1;

__END__
