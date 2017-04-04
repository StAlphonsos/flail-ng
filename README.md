# Flail - a secure command-line MUA in Perl #

An MUA for the command-line in Modern Perl.  Security is a front-line
concern, usability right there with it and honestly almost the same
thing.

* Three kinds of tests: unit, integration, vul (by e.g. CVE);
* Privsep/sandboxes;
* Only rely on modern, actively-maintained libraries;
* Usable crypto support: reop, opmsg, gpg.

Other features:

* Integrated support for external mail indexers, e.g. mairix, mu
  but can be used w/o them (no hard dep);
* Comfy CLI via Devel::REPL, can be used "bare", feels like a
  Unixy MM (if you're old enough to remember :-);
* If used in tmux, tmux becomes our UI "skin" and you can have
  multiuple flail panes in the same window, mouse-click-based
  actions, etc.;
* Can be used as a webmail interface with certain restrictions.

## Dependencies

* [Moose](http://metacpan.org/pod/Moose);
* [Mail::Box](http://perl.overmeer.net/mailbox/);
* [App::Cmd](http://metacpan.org/pod/App::Cmd);
* [Devel::REPL](http://metacpan.org/pod/Devel::REPL);
* [Mojolicious](http://metacpan.org/pod/Mojolicious).
