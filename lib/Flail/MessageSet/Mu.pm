#! perl
# -*- mode:perl;tab-width:8;perl-indent-level:8;indent-tabs-mode:t -*-

=pod

=head1 NAME

Flail::MessageSet::Mu - brief description

=head1 SYNOPSIS

  use Flail::MessageSet::Mu;
  blah;

=head1 DESCRIPTION

Describe the module with real words.

=head1 LICENSE

ISC/BSD; see LICENSE file in source distribution.

=cut

package Flail::MessageSet::Mu;
use Moose;
use Flail::Util qw(dumpola test_warn);
use mup;

extends "Flail::MessageSet::Handler";

has "query" => (is => "rw", isa => "Str", required => 1);
has "mup" => (is => "rw", isa => "mup");
has "results" => (is => "rw", isa => "Maybe[HashRef]");
has "maxnum" => (is => "rw", isa => "Int", default => 100);
has "threads" => (is => "rw", isa => "Bool", default => 0);
has "sortfield" => (is => "rw", isa => "Str", default => "date");
has "reverse" => (is => "rw", isa => "Bool", default => 0);

sub BUILD {
	my($self,$params) = @_;
	$self->mup(mup->new(verbose => $ENV{"TEST_VERBOSE"}))
	    unless $self->mup;
	my $opt = sub {
		my($name) = @_;
		( $name => 
		  exists($params->{$name}) ? $params->{$name} : $self->$name )
	};
	my %query_opts = ( map { &$opt($_) }
			   qw(maxnum threads sortfield reverse) );
	$query_opts{"query"} = $self->query;
	test_warn("# query opts: ".dumpola(\%query_opts));
	$self->results($self->mup->find(query => $self->query));
}

sub count	{ shift->results->{"found"} }
sub this	{ $_[0]->results->{"results"}->[$_[0]->idx + $_[1]] }

__PACKAGE__->meta->make_immutable;

1;

__END__
