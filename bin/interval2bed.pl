#!/usr/bin/env perl
use strict;
use warnings;

=pod

>AM236595.1 Haliotis tuberculata mRNA for actin (actin gene) from haemocyte cells
1454 - 1461
2945 - 2997

=cut

my $in = $ARGV[0];
my $out = $ARGV[1];
open(FILE, $in) or die "cannot open file $in for reading: $!";
open(OUT, ">$out") or die "cannot open file $out for writing: $!";

my $currentId;
while(<FILE>) {
    chomp;
    if (/^>(\S+)/) {
	$currentId = $1;
    } elsif (/(\d+)\s\-\s(\d+)/) {
        my $start = $1 - 1; # NOTE:  bedgraph format is zero based half open
        my $end = $2;
        print OUT "$currentId\t$start\t$end\n";
    } else {
	die "unexepected interval format.  line: $_\n";
    }
}
close FILE;
close OUT;
