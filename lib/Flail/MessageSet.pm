#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::MessageSet - A container for a set of messages

=head1 SYNOPSIS

  use Flail::MessageSet;
  blah;

=head1 DESCRIPTION

Describe the module with real words.

=cut

package Flail::MessageSet;
use Moose;
use POSIX qw(_exit);
use Flail::ChildProcess;
use Flail::Message;
use Flail::MessageSet::Maildir;
use Try::Tiny;
use overload '""' => \&to_string;

extends "Flail::Reporter";

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
	$self->log("#$$ _dispatch name=$name args=",\@args);
	if ($self->in_parent) {
		return $self->privsep_child->req($name,@args);
	}
	try {
		$self->log("#$$ _dispatch $name using real=".$self->real);
		return $self->real->$name(@args);
	} catch {
		$self->log("#$$ dispatch $name got error: @_");
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

# initialize the sandbox in a child process by doing whatever it is
# that must be done pre-pledge.
sub _sandbox_init {
	$_[0]->log("#$$ initializing sandbox");
	# had to use unshift @INC, sub { warn } to suss this out, thx afresh1@
	use App::Cmd::Command::commands;
	use App::Cmd::Command::help;
	use App::Cmd::Command::version;
	use AutoLoader;
	use B::Hooks::EndOfScope::XS;
	use B::Hooks::EndOfScope;
	use Carp::Heavy;
	use Date::Format;
	use Date::Parse;
	use Devel::REPL::Error;
	use Devel::REPL;
	use Encode::Alias;
	use Encode::Config;
#	use Encode::ConfigLocal;	# XXX not sure about this
	use Encode::Encoding;
	use Encode;
	use Errno;
	use File::Copy;
	use File::Glob;
	use File::Path;
	use File::Remove;
	use File::Temp;
	use Flail::App::Command::ls;
	use Flail::App::Command::repl;
	use Flail::App::Command::server;
	use Flail::ChildProcess;
	use Flail::Message;
	use Flail::MessageSet::Handler;
	use Flail::MessageSet::Maildir;
	use Flail::MessageSet;
	use Getopt::Long::Descriptive::Opts;
	use Getopt::Long::Descriptive::Usage;
	use Getopt::Long::Descriptive;
	use Getopt::Long;
	use IO::Lines;
	use IO::ScalarArray;
	use IO::WrapTie;
	use JSON::XS;
	use JSON;
	use MIME::Base64;
	use MIME::QuotedPrint;
	use MIME::Type;
	use MIME::Types;
	use Mail::Address;
	use Mail::Box::Dir::Message;
	use Mail::Box::Dir;
	use Mail::Box::FastScalar;
	use Mail::Box::Locker;
	use Mail::Box::Maildir::Message;
	use Mail::Box::Maildir;
	use Mail::Box::Message;
	use Mail::Box::Parser::C;	# dynloaded .so file
	use Mail::Box::Parser;
	use Mail::Box;
	use Mail::Message::Body::Delayed;
	use Mail::Message::Body::Encode;
	use Mail::Message::Body::File;
	use Mail::Message::Body::Lines;
	use Mail::Message::Body::Multipart;
	use Mail::Message::Body::Nested;
	use Mail::Message::Body;
	use Mail::Message::Construct;
	use Mail::Message::Field::Fast;
	use Mail::Message::Field::Full;
	use Mail::Message::Field;
	use Mail::Message::Head::Complete;
	use Mail::Message::Head::Delayed;
	use Mail::Message::Head::Partial;
	use Mail::Message::Head;
	use Mail::Message::Part;
	use Mail::Message;
	use Mail::Reporter;
	use MooseX::Object::Pluggable;
#	use Object::Realize::Later;	# no point in doing this, read the POD
	use OpenBSD::Pledge;
	use Params::Validate::Constants;
	use Params::Validate::XS;
	use Params::Validate;
	use PerlIO::encoding;
	use PerlIO;
	use Socket;
	use Sub::Exporter::Util;
	use Sys::Hostname;
	use Term::ReadLine::Gnu::XS;
	use Term::ReadLine::Gnu;
	use Term::ReadLine;
	use Text::Abbrev;
	use Time::Local;
	use Time::Zone;
	use Types::Serialiser;
	use Variable::Magic;
	use common::sense;
	use filetest 'access';
	use integer;
#	use namespace::autoclean;	# also counter-productive
#	use namespace::clean::_Util;	# ...
#	use namespace::clean;		# ......
	use utf8;
	$_[0]->log("#$$ sandbox initialized");
}

# fork a privsep child to do actual parsing of email
sub BUILD {
	my($self,$params) = @_;
	if ($params->{"no_privsep"}) {
		# privsep turned off - load the data now
		$self->load_data();
	} else {
		# privsep - fork the child
		my $child = Flail::ChildProcess->new(
			obj => $self,
			app => $params->{"app"},
			name => "maildir reader",
			promises => "stdio rpath",
			sandbox_init => \&_sandbox_init,
		    );
		$self->privsep_child($child);
		$self->log("#$$ forked privsep child $child");
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
	$self->log("#$$ MessageSet child loading data");
	$self->load_data();
	$self->log("#$$ MessageSet child dropping into loop");
	_exit($self->privsep_child->loop());
}

# use the Query constructor to get privsep
sub Query { shift->new(@_)->run() }

__PACKAGE__->meta->make_immutable;

1;

__END__
