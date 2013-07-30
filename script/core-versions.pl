#!/usr/bin/env perl
# make versions list out of Module::CoreList

use strict;
use Module::CoreList;
use version;

my(%seen, @versions);

for my $v (map version->new($_), sort keys %Module::CoreList::released) {
    next if $v < version->new("5.8.3");
    my $vstr = $v->normal =~ s/^v//r;
    next if $seen{$vstr}++;
    push @versions, $vstr;
}

my $js;
$js = "var perl_versions = [\n";
for my $v (@versions) {
    $js .= "[ '$v', 0 ],\n";
}

$js =~ s/,\n$/\n/;
$js .= "];\n";

open my $out, ">", "static/perl-versions.js" or die $!;
print $out $js;








