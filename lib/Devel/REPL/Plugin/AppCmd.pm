#! perl

=pod

=head1 NAME

Devel::REPL::Plugin::AppCmd - Make commands in an App::Cmd object visible

=head1 DESCRIPTION

This plugin modifies a L<Devel::REPL> instance so that all commands
visible in an L<App::Cmd> instance become top-level commands in the
REPL by default, and become the command language in the REPL shell.

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
        $_repl->app_cmd->execute_command($app_cmd, $app_opt, @app_args);
    };
}

1;

__END__

=pod

=head1 SEE ALSO

We live in splendid isolation.

=head1 AUTHOR

  attila <attila@stalphonsos.com>

=head1 LICENSE

Copyright (C) 2015 by attila <attila@stalphonsos.com>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.

=cut

##
# Local variables:
# mode: perl
# tab-width: 4
# perl-indent-level: 4
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# indent-tabs-mode: nil
# comment-column: 40
# End:
##
