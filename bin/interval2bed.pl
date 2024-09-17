#!/usr/bin/env perl
use strict;
use warnings;

my $in = $ARGV[0];
my $out = $ARGV[1];
open(FILE, $in) or die "cannot open file $in for reading: $!";
open(OUT, ">$out") or die "cannot open file $out for writing: $!";

while(<FILE>) {
    chomp;
    my ($seq, $start, $end) = split(/\t/, $_);

    $seq =~ /^>(\S+)/;
    print OUT "$1\t$start\t$end\n";
}
close FILE;
close OUT;
