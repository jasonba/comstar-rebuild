#!/usr/bin/perl

#
# Name		: tpg.pl
# Author	: Jason Banham
# Date		: 17th August 2015
# Usage		: tpg.pl itadm-list-tpg-v.out
# Purpose	: Recreate the COMSTAR target portal group settings from a saved Collector file
# Version	: 0.01
# History	: 0.01 - Initial version
#

use strict;

my $num_args = $#ARGV + 1;

if ( $num_args < 1 ) {
    print "Usage: tpg.pl itadm-list-tpg-v.out\n";
    exit;
}

open (my $file, "<", $ARGV[0]) || die "Can't read file comstar target portal group file: $!";
my (@tpg_list) = <$file>;
close($file);

chomp(@tpg_list);
my ($tpg_lines) = scalar @tpg_list;
my $index = 0;	

while ($index < $tpg_lines) {
    my ($header) = split /\s+/, $tpg_list[$index];
    if ( $header =~ /TARGET/ ) {
	$index++;
    }
    my ($tpg_name, $portal_count) = split /\s+/, $tpg_list[$index];
    my $cmd = "itadm create-tpg " . $tpg_name . " ";
    $index++;
    my ($tag, $portal) = split /:\s+/, $tpg_list[$index];
    $portal =~ s/,/ /g;
    $cmd = $cmd . $portal;
    printf("%s\n", $cmd);
    $index++;
}

