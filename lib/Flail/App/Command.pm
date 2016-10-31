=pod

=head1 NAME

Flail::App::Command - base class for all flail commands

=head1 SYNOPSIS

  # It's a base class

=head1 DESCRIPTION

Provides common data and behavior for all flail commands.

=cut

package Flail::App::Command;
use strict;
use warnings;
use App::Cmd::Setup -command;

sub emit {
    shift if ref($_[0]);
    print "[emit] @_\n";
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
