## flail, A command-line MUA in Perl

use ExtUtils::MakeMaker;
do "./lib/Flail.pm";

sub SRC { "lib/@_" }
sub DST { '$(INST_LIBDIR)/'."@_" }
sub PAIR { ( SRC(@_) => DST(@_) ) }

print STDERR "Welcome to flail v.$Flail::VERSION\n\n";
WriteMakefile(
    AUTHOR => 'attila <attila@stalphonsos.com>',
    ABSTRACT => 'Command-line MUA in Perl',
    NAME => 'flail',
    VERSION => $Flail::VERSION,
    EXE_FILES => [ 'bin/flail' ],
    PREREQ_PM => {
	'Mail::Box' => 0,
	'Net::SMTP' => 0,
	'App::Cmd' => 0,
	'Devel::REPL' => 0,
	'Moose' => 0,
	'mup' => 0,
    },
    PM => {
	PAIR('Flail.pm'),
	PAIR('Flail/App.pm'),
	PAIR('Flail/App/Command.pm'),
	PAIR('Flail/App/Command/repl.pm'),
	PAIR('Flail/App/Command/server.pm'),
	PAIR('Devel/REPL/Plugin/AppCmd.pm'),
    }
);
sub MY::postamble {
    print STDERR "\nExamples will be installed somewhere like /usr/local/share/examples/flail\nThey are also in the eg/ subdirectory of this distribution.\n\n";
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
	\$(RM) -f *.flc *.bak *~ .tec*

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
__MyTaRgEt__
}
