#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::Util - utilities without any other natural home

=head1 SYNOPSIS

  # nothing exported by default
  use Flail::Util qw(...);

=head1 DESCRIPTION

Utilities with no other natural home go here.

=head1 EXPORTED SUBS

=cut

package Flail::Util;
use Data::Dumper;
use POSIX;
use Scalar::Util qw(looks_like_number blessed);
use parent qw(Exporter);
use vars qw(@EXPORT_OK %EXPORT_TAGS $TIME_FMT %CURSES);

$TIME_FMT = "%Y-%m-%d %H:%M:%S";
@EXPORT_OK = qw(
    affirmative basename basename_env clean curse defor defkey
    dirname dirname_env dumpola hexdump msgfy ts screen_columns test_warn);
%EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

=pod

=over 4

=item * basename $path

Like the POSIX shell utility of the same name: return the last
component of the filesystem path C<$path>

=item * dirname $path

Similar to basename: returns all but the last component of C<$path>

=item * basename_env $envar[, $envar2]

=item * dirname_env $envar[, $envar2]

=back

=cut

sub basename	{ (split(/\//, $_[0]))[-1] }
sub dirname	{ my @p = split(/\//, $_[0]); join("/", @p[0..$#p-1]); }

sub basename_env{
	return basename($ENV{$_[0]}) if exists $ENV{$_[0]};
	shift;
	return @_ ? basename_env(@_) : undef;
}

sub dirname_env {
	return dirname($ENV{$_[0]}) if exists $ENV{$_[0]};
	shift;
	return @_ ? dirname_env(@_) : undef;
}


=pod

=over 4

=item * dumpola $something

Shorthand for:

  Data::Dumper->new(\@_)->Terse(1)->Indent(0)->Dump;

=item * hexdump $bytes[, $sep]

Unpack a string of bytes into a hex string.  If the optional second
parameter is passed it is used to join together the the hex byte
strings; the default is a space.

=item * test_warn $message

Call L<warn> on our arguments if the C<TEST_VERBOSE> environment
variable is set.

=item * ts [$time_t]

Return a string timestamp in the default format; if no argument is
given, the current time is used, otherwise send us an epoch.

=item * clean $string

Return C<$string> with all leading and trailing whitespace removed.

=item * affirmative $input

Return true if C<$input> is a string that represents an affirmative
response to a yes/no question, false otherwise.

=item * defor $value,$default

Returns C<$value> if it is defined, C<$default> otherwise.

=item * defkey $hashref,$key,$default

Returns C<$hashref->{$key}> if it exists (even if it is undef)
and C<$default> if it does not.

=back

=cut

sub dumpola	{ Data::Dumper->new(\@_)->Terse(1)->Indent(0)->Dump; }
sub hexdump	{ join(@_ > 1 ? $_[1] : " ",unpack("(H2)*",$_[0])) }
sub test_warn	{ warn("@_\n") if $ENV{"TEST_VERBOSE"} }
sub ts		{ POSIX::strftime($TIME_FMT,localtime(@_ ? $_[0] : time)) }
sub clean	{ my $s = shift; $s =~ s/(^\s+|\s+$)//gs; $s }
sub affirmative { ($_[0] =~ /^(yes|t|ok|)$/i) ? 1 : 0 }
sub defor	{ defined($_[0]) ? $_[0] : $_[1] }
sub defkey	{ exists($_[0]->{$_[1]}) ? $_[0]->{$_[1]} : $_[2] }

=pod

=over 4

=item * msgfy $something

=back

=cut

sub msgfy {
	my($what) = @_;
	return "-UNDEF-"	unless defined $what;
	return "$what"		unless     ref $what;
	return dumpola($what);
}

=pod

=over 4

=item * ($width, $height) = screen_columns()

=back

=cut

sub screen_columns {
	my($width,$height);
	unless (exists $ENV{'CGI'}) {
		if (-t 0) {
			chomp(my $line = `/bin/stty -a | /usr/bin/head -1`);
			($width,$height) = ($2,$1)
			    if $line =~ /;\s(\d+)\srows;\s(\d+)\scol/;
		}
	}
	return($width,$height);
}

=pod

=over 4

=item * curse $thing

If C<$thing> is a blessed reference attempt to turn it into an
unblessed reference containing data that can be used to reconstruct an
equivalent blessed reference in another address space.  If the object
understands a C<curse> method it will be invoked, otherwise
stringification is used.  Unblessed arrayrefs and hashrefs are
descended into recursively in the natural way.  Scalars and undef pass
through unchanged.

=back

=cut

%CURSES = (
	"Mail::Address" => sub { "".shift },
	"Mail::Message::Body::Delayed" => sub { "-delayed-" },
);

sub curse {
	my $thing = shift;
	my $rr = ref($thing);
	my $rez;
	if (!$rr) {
		$rez = defined($thing) ? $thing : undef;
	} elsif (blessed($thing)) {
		if ($thing->can("curse")) {
			$rez = $thing->curse();
		} elsif (exists($CURSES{$rr})) {
			my $curz = $CURSES{$rr};
			$rez = &$curz($thing);
		} else {
			$rez = "$thing";
		}
	} elsif ($rr eq "ARRAY") {
		$rez = [ map { curse($_) } @$thing ];
	} elsif ($rr eq "HASH") {
		$rez = { map { $_ => curse($thing->{$_}) } keys %$thing };
	} else {
		die("unhandled ref curse $rr ($thing)");
	}
	return $rez;
}

1;

__END__
