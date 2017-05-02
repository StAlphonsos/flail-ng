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

=cut

package Flail::MessageSet;
use Modern::Perl;
use Moose;
use POSIX qw(_exit);
use Flail::ChildProcess;
use Flail::Message;
use Flail::MessageSet::Maildir;
use Flail::Util qw(dumpola test_warn);
use Try::Tiny;
use overload '""' => \&to_string;

# turn RPC results back into object
sub uncurse_msg { @_ ? Flail::Message->new(@_) : undef }

our $RPC_METHODS = {
	"count" => undef,
	"idx" => undef,
	"this" => \&uncurse_msg,
	"first" => \&uncurse_msg,
	"final" => \&uncurse_msg,
	"next" => \&uncurse_msg,
	"prev" => \&uncurse_msg,
	"is_exhausted" => undef,
};

has "query" => (is => "rw", isa => "Maybe[Str]");
has "folder" => (is => "rw", isa => "Maybe[Str]");
has "privsep_child" => (is => "rw", isa => "Maybe[Flail::ChildProcess]");
has "real" => (is => "rw", isa => "Maybe[Flail::MessageSet::Handler]");
# w/no privsep delegation makes this easy:
#	handles => [qw[count this finish first final next prev is_exhausted]]);
# w/privsep things become a little harder...

sub to_string {
	my($self) = @_;
	return "".$self->real if $self->real;
	return sprintf("<%s: %d of %d>",$self->folder,$self->idx,$self->count);
}

sub in_parent { $_[0]->privsep_child && $_[0]->privsep_child->pid }

# parent: make RPC request to child
# child: invoke real method on underlying object
sub _dispatch {
	my($self,$name,@args) = @_;
	warn("$$ _dispatch name=$name args=@args child=".
	     $self->privsep_child."\n");
	if ($self->in_parent) {
		return $self->privsep_child->req($name,@args);
	}
	try {
		warn("$$ _dispatch $name using real=".$self->real."\n");
		return $self->real->$name(@args);
	} catch {
		warn ("$$ dispatch $name got error: @_\n");
	};
}

sub rpc_methods { $RPC_METHODS; }

# methods we would delegate to $self->real if we could
sub idx		{ shift->_dispatch("idx",@_) }
sub count	{ shift->_dispatch("count",@_) }
sub this	{ shift->_dispatch("this",@_) }
sub first	{ shift->_dispatch("first",@_) }
sub final	{ shift->_dispatch("final",@_) }
sub next	{ shift->_dispatch("next",@_) }
sub prev	{ shift->_dispatch("prev",@_) }
sub is_exhausted{ shift->_dispatch("is_exhausted",@_) }

# fork a privsep child to do actual parsing of email
sub BUILD {
	my($self,$params) = @_;
	if ($params->{"no_privsep"}) {
		# privsep turned off - load the data now
		$self->load_data();
	} else {
		# privsep - fork the child
		my $child = Flail::ChildProcess->new(
			"obj" => $self,
			"app" => $params->{"app"},
			"name" => "maildir reader",
			"promises" => "stdio rpath",
		    ) unless $params->{"no_privsep"};
		$self->privsep_child($child);
		warn("$$ forked privsep child $child\n");
	}
}

# parent: kill/reap the child
sub finish	{ $_[0]->privsep_child->finish() if $_[0]->in_parent; 1 }

sub load_data {
	$_[0]->real(Flail::MessageSet::Maildir->new(folder => $_[0]->folder));
	return $_[0];
}

# parent: return immediately
# child: run the rpc loop
sub run {
	my($self) = @_;
	return $self if $self->in_parent;
	warn("$$ MessageSet child loading data\n");
	$self->load_data();
	warn("$$ MessageSet child dropping into loop\n");
	_exit($self->privsep_child->loop());
}

# use the Query constructor to get privsep
sub Query { shift->new(@_)->run() }

__PACKAGE__->meta->make_immutable;

1;

__END__
