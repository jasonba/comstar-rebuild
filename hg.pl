#!/usr/bin/perl

#
# Name          : hg.pl
# Author        : Jason Banham
# Date          : 13th August 2015 / 22nd March 2019
# Usage         : hg.pl stmfadm-list-hg-v.out
# Purpose       : Recreate the COMSTAR host group settings from a saved Collector file
# Version       : 0.02
# History       : 0.01 - Initial version
#                 0.02 - Cluster switch code added
#

use strict;
use Getopt::Std;

my $cluster;
my $cmd = "stmfadm";
my $local_cmd;

my $num_args = $#ARGV + 1;

if ( $num_args < 1 ) {
    print "Usage: hg.pl stmfadm-list-hg-v.out\n";
    exit;
}

# declare the perl command line flags/options we want to allow
my %options=();
getopts("c", \%options);

if (defined $options{c}) {
    $cmd = "stmfha";
}

open (my $file, "<", $ARGV[0]) || die "Can't read file: $ARGV[0]";
my (@hostgroup_list) = <$file>;
close($file);

chomp(@hostgroup_list);
my ($hostgroup_lines) = scalar @hostgroup_list;
my $index = 0;

while ($index < $hostgroup_lines) {
    if ( $hostgroup_list[$index] =~ /Host Group:.+/ ) {
	my ($tag, $hg_name) = split /: /, $hostgroup_list[$index];
        $local_cmd = $cmd . " create-hg " . $hg_name;
        printf("%s\n", $local_cmd);
#	printf("stmfadm create-hg %s\n", $hg_name);
	$index++;
 	while ( $hostgroup_list[$index] !~ /Host Group:.+/ && $index < $hostgroup_lines) {
	    my ($member, $iqn) = split /: /, $hostgroup_list[$index];
            $local_cmd = $cmd . " add-hg-member -g " . $hg_name . " " . $iqn;
            printf("%s\n", $local_cmd);
#            printf("stmfadm add-hg-member -g %s %s\n", $hg_name, $iqn);
	    $index++;
        }
	$index--;
    }
    $index++;
}

