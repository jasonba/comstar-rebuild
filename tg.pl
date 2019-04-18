#!/usr/bin/perl

#
# Name		: tg.pl
# Author	: Jason Banham
# Date		: 13th August 2015 - 29th October 2015 | 22nd March 2019
# Usage		: tg.pl stmfadm-list-tg-v.out
# Purpose	: Recreate the COMSTAR target group settings from a saved Collector file
# Version	: 0.04
# History	: 0.01 - Initial version
#		  0.02 - Now handles empty target groups and is smarter about offlining and onling the target
#		  0.03 - Fixed bug during offline/online targets so we do this for all targets, not just
#		         the first one in the list
#                 0.04 - Cluster switch code added
#

use strict;
use Getopt::Std;

my $cluster;
my $cmd = "stmfadm";
my $local_cmd;

my $num_args = $#ARGV + 1;

if ( $num_args < 1 ) {
    print "Usage: tg.pl stmfadm-list-tg-v.out\n";
    exit;
}

# declare the perl command line flags/options we want to allow
my %options=();
getopts("c", \%options);

if (defined $options{c}) {
    $cmd = "stmfha";
}

open (my $file, "<", $ARGV[0]) || die "Can't read file: $ARGV[0]";
my (@targetgroup_list) = <$file>;
close($file);

chomp(@targetgroup_list);
my ($targetgroup_lines) = scalar @targetgroup_list;
my $index = 0;

while ($index < $targetgroup_lines) {
    if ( $targetgroup_list[$index] =~ /Target Group:.+/ ) {
	my ($tag, $tg_name) = split /: /, $targetgroup_list[$index];
        $local_cmd = $cmd . " create-tg " . $tg_name;
        printf("%s\n", $local_cmd);
#	printf("stmfadm create-tg %s\n", $tg_name);
	$index++;
        my ($member, $iqn) = split /: /, $targetgroup_list[$index];
        if ( $iqn ) {
     	    while ( $targetgroup_list[$index] !~ /Target Group:.+/ && $index < $targetgroup_lines) {
                my ($member, $iqn) = split /: /, $targetgroup_list[$index];
                $local_cmd = $cmd . " offline-target " . $iqn;
                printf("%s\n", $local_cmd);
                $local_cmd = $cmd . " add-tg-member -g " . $tg_name . " " . $iqn;
                printf("%s\n", $local_cmd);
                $local_cmd = $cmd . " online-target " . $iqn;
                printf("%s\n", $local_cmd);

# 	         printf("stmfadm offline-target %s\n", $iqn);
#                printf("stmfadm add-tg-member -g %s %s\n", $tg_name, $iqn);
#                printf("stmfadm online-target %s\n", $iqn);
	        $index++;
            }
	    $index--;
        }
    }
    printf("\n");
    $index++;
}

