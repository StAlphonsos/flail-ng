# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t;perl-continued-statement-offset:0 -*-

## flail, A command-line MUA in Perl

use ExtUtils::MakeMaker;
use IO::All;
do "./lib/Flail.pm";

#sub SRC { "lib/@_" }
#sub DST { '$(INST_LIBDIR)/'."@_" }
#sub PAIR { ( SRC(@_) => DST(@_) ) }
sub SRC { "@_" }
sub DST { my $d = "@_"; $d =~ s,^lib/,,; '$(INST_LIBDIR)/'.$d }
sub PAIR { ( SRC(@_) => DST(@_) ) }

print STDERR "Welcome to flail v.$Flail::VERSION\n\n";
WriteMakefile(
	AUTHOR => 'attila <attila@stalphonsos.com>',
	ABSTRACT => 'Command-line MUA in Perl',
	NAME => 'flail',
	VERSION => $Flail::VERSION,
	EXE_FILES => [ 'bin/flail' ],
	PREREQ_PM => {
		'App::Cmd' => 0,
		'Devel::REPL' => 0,
		'IO::All' => 0,
		'JSON' => 0,
		'Mail::Box' => 0,
		'Modern::Perl' => 0,
		'Moose' => 0,
		'Net::SMTP' => 0,
		'Try::Tiny' => 0,
	},
	PM => { map { PAIR($_) } grep {/^lib/} @{io("MANIFEST")} },
);
sub MY::postamble {
    return <<__MyTaRgEt__;
\# dist checksum and signing fu

OPENSSLCMD?=openssl
MD5CMD?=\$(OPENSSLCMD) dgst -md5
SHA1CMD?=\$(OPENSSLCMD) dgst -sha1
RIPEMD160CMD?=\$(OPENSSLCMD) dgst -ripemd160
GPGCMD?=gpg
GPGKEYID?=0x4FFCBB9C
RELEASEDIR?=\$\$HOME/release
RELEASETARBALL?=\$(NAME)-\$(VERSION).tar.gz
RELEASEFILES?=\$(RELEASETARBALL) \$(RELEASETARBALL).md5 \$(RELEASETARBALL).sha1 \$(RELEASETARBALL).ripemd160 \$(RELEASETARBALL).asc
RELEASETARGETS?=dist md5 sha1 ripemd160 asc
RM?=/bin/rm
SHAREDIR?=\$(PREFIX)/share
EXAMPLEDIR?=\$(SHAREDIR)/examples/\$(NAME)
EXAMPLES?=eg
MKDIR_P?=mkdir -p

clean::
	\$(RM) -f *.flc *.bak *~ .tec* flail*.log

force-releasefiles: cleanrelease releasefiles

distclean:: cleanrelease

install :: \$(EXAMPLEDIR)
	\$(CP) dot.flailrc \$(EXAMPLEDIR)
	(cd \$(EXAMPLES); \$(TAR) cf - `grep eg/ ../MANIFEST | sed -e 's|eg/||'`) | (cd \$(EXAMPLEDIR); \$(TAR) xf -)

\$(EXAMPLEDIR) :
	\$(MKDIR_P) \$(EXAMPLEDIR)

cleanrelease:
	-\$(RM) -f \$(RELEASEFILES)

releasefiles: \$(RELEASETARGETS)

release: releasefiles
	\@-[ -d \$(RELEASEDIR) ] && \$(MV) \$(RELEASEFILES) \$(RELEASEDIR)
	\@echo Moved release files to \$(RELEASEDIR): \$(RELEASEFILES)

md5: \$(RELEASETARBALL)
	\$(MD5CMD) \$(RELEASETARBALL) > \$(RELEASETARBALL).md5

sha1: \$(RELEASETARBALL)
	\$(SHA1CMD) \$(RELEASETARBALL) > \$(RELEASETARBALL).sha1

ripemd160: \$(RELEASETARBALL)
	\$(RIPEMD160CMD) \$(RELEASETARBALL) > \$(RELEASETARBALL).ripemd160

asc: \$(RELEASETARBALL)
	\$(GPGCMD) --sign --default-key \$(GPGKEYID) --detach --armor \$(RELEASETARBALL)

# e.g. $ make search key=some_method
search ::
	\@find lib \\( -perm -1 -a ! -type d \\) -o -name '*.pm' -o -name '*.t' -o -name '*.pl' | xargs grep -n \${grep_opts} \${key}

reconf ::
	\@make distclean; perl Makefile.PL

smoke ::
	\@make test TEST_FILES=t/000-load-everything.t
__MyTaRgEt__
}
