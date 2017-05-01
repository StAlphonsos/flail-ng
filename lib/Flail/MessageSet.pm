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
use Flail::ChildProcess;
use Flail::Message;
use Flail::MessageSet::Maildir;
use Flail::Util qw(dumpola test_warn);
use overload '""' => \&to_string;

# turn RPC results back into object
sub uncurse_msg { @_ ? Flail::Message->new(@_) : undef }

our $RPC_METHODS = {
	"count" => undef,
	"this" => \&uncurse_msg,
	"finish" => undef,
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
	return "<a folder: ".$self->folder.">";
}

# parent: make RPC request to child
# child: invoke real method on underlying object
sub _dispatch {
	my($self,$name,@args) = @_;
	warn("$$ $self _dispatch name=$name args=@args\n");
	return ($self->privsep_child && $self->privsep_child->pid) ?
	    $self->privsep_child->req($name,@args) :
	    $self->real->$name(@args);
}

sub rpc_methods { $RPC_METHODS; }

# methods we would delegate to $self->real if we could
sub count	{ shift->_dispatch("count",@_) }
sub this	{ shift->_dispatch("this",@_) }
sub finish	{ shift->_dispatch("finish",@_) }
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
			"promises" => "rpath",
		    ) unless $params->{"no_privsep"};
		$self->privsep_child($child);
		warn("$$ forked privsep child $child\n");
	}
}

# parent: kill/reap the child
sub DEMOLISH { $_[0]->privsep_child->finish() if $_[0]->privsep_child }

sub load_data {
	$_[0]->real(Flail::MessageSet::Maildir->new(folder => $_[0]->folder));
	return $_[0];
}

# child: run the rpc loop
# parent: return immediately
sub run {
	my($self) = @_;
	return $self if $self->privsep_child && $self->privsep_child->pid;
	warn("$$ MessageSet child loading data\n");
	$self->load_data();
	warn("$$ MessageSet child dropping into loop\n");
	exit($self->privsep_child->loop());
}

# use the Query constructor to get privsep
sub Query { shift->new(@_)->run() }

__PACKAGE__->meta->make_immutable;

1;

__END__
