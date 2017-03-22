#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Devel::REPL::Plugin::AppCmd - Make commands in an App::Cmd object visible

=head1 DESCRIPTION

This plugin modifies a L<Devel::REPL> instance so that all commands
visible in an L<App::Cmd> instance become top-level commands in the
REPL by default, and become the command language in the REPL shell.

=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Devel::REPL::Plugin::AppCmd;
use strict;
use warnings;

BEGIN {
    $Devel::REPL::Plugin::AppCmd::AUTHORITY = 'cpan:ATTILA';
}
$Devel::REPL::Plugin::AppCmd::VERSION = '1.003026'; # XXX?
use Devel::REPL::Plugin;
use namespace::autoclean;

has 'app_cmd' => (
	is => 'rw',
	lazy => 1, default => sub { {} }
    );

# Need Devel::REPL::Plugin::LexEnv
sub BEFORE_PLUGIN {
	my ($self) = @_;
	$self->load_plugin('LexEnv');
}

# Override the compile method
sub compile {
	my ($_repl, @args) = (shift, shift);
	local @ARGV = @args;
	# If it starts with the Perl escape character (comma)
	# strip the escape and deal with it as Perl:
	if (@args && $args[0] =~ /^,/) {
		$args[0] =~ s/^,//;
		my $compiled = eval qq!sub { @args }!;
		return $compiled;
	}
	# Otherwise, use the App::Cmd instance: look it up ...
	my ($cmd, $opt, @a) = $_repl->app_cmd->prepare_command(
		map { split(/\s+/, $_) } @args
	    );
	# ... bind lexicals that our compiled sub can see ...
	$_repl->lexical_environment->set_context(
		app => { '$cmd' => $cmd, '$opt' => $opt, '@args' => \@a }
	    );
	# ... and return a compiled sub that executes it App::Cmd-style
	return sub {
		my($app_cmd, $app_opt, @app_args);
		$_repl->app_cmd->execute_command($app_cmd,$app_opt,@app_args);
	};
}

1;

__END__
