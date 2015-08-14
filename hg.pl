#!/usr/bin/perl

#
# Name          : hg.pl
# Author        : Jason Banham
# Date          : 13th August 2015
# Usage         : hg.pl stmfadm-list-hg-v.out
# Purpose       : Recreate the COMSTAR host group settings from a saved Collector file
# Version       : 0.01
# History       : 0.01 - Initial version
#

use strict;

my $num_args = $#ARGV + 1;

if ( $num_args < 1 ) {
    print "Usage: hg.pl stmfadm-list-hg-v.out\n";
    exit;
}

open (my $file, "<", $ARGV[0]) || die "Can't read file numlist: $!";
my (@hostgroup_list) = <$file>;
close($file);

chomp(@hostgroup_list);
my ($hostgroup_lines) = scalar @hostgroup_list;
my $index = 0;

while ($index < $hostgroup_lines) {
    if ( $hostgroup_list[$index] =~ /Host Group:.+/ ) {
	my ($tag, $hg_name) = split /: /, $hostgroup_list[$index];
	printf("stmfadm create-hg %s\n", $hg_name);
	$index++;
 	while ( $hostgroup_list[$index] !~ /Host Group:.+/ && $index < $hostgroup_lines) {
	    my ($member, $iqn) = split /: /, $hostgroup_list[$index];
            printf("stmfadm add-hg-member -g %s %s\n", $hg_name, $iqn);
	    $index++;
        }
	$index--;
    }
    $index++;
}

