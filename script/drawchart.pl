#!/usr/bin/env perl
use strict;
use Time::Piece;

sub versionify {
    my $v = shift;
    $v =~ /^5\.(\d{3})(\d{3})/
      and return join '.', 5, $1+0, $2+0;
}

sub probably_testers {
    local $_ = shift;
    return 1 if /^199\.91\.17[01]\./ or /^199\.182\.120\./; # Travis CI
    return 0;
}

my(%uniq, %versions);

while (<>) {
    my @line = split / /, $_;
    my($ip, $perl) = @line[0, 12];
    next if probably_testers($ip);
    if ($perl =~ /^perl\/(5\.\d{6})"$/) {
        $uniq{"$ip-$1"}++ or $versions{$1}++;
    }
}

my $js_data = join ",\n", map { "[ '@{[versionify($_)]}', $versions{$_} ]" } sort keys %versions;

my $time = Time::Piece->new;
my $date = join ",", $time->year, $time->mon, $time->mday;

print qq/callback({"date": [$date], "data": [ ['Version', 'Requests'], $js_data ]});/;
