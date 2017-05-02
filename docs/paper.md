Title: Writing a secure MUA in Perl
Author: attila@stalphonsos.com
Date: 2017-03-24
Base Header Level: 4
latex mode:         memoir
latex input:        mmd-memoir-header
latex input:        mmd-memoir-begin-doc
latex footer:       mmd-memoir-footer


# Flail Notes

To be turned into some kind of pub if this works out.

Privsep/pledge: how do libraries like Mail::Box, etc. deal with
pledge and privsep?  where are things decoded?  how do we apply
the privsep pattern to an MUA.  This is one of the central questions
of this project.

## notes

* 2017-04-04

Taint checking makes local::lib not work.  Interesting dilemma.

Struggling with what code should be where, have decided to take simple
approach first and do privsep next with just what I have.

Sometimes you have to not do what you want in order to figure out how
to do what you want.  Or, even better: to figure out what it means.
