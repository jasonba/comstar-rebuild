#!/usr/bin/perl

#
# Name		: tg.pl
# Author	: Jason Banham
# Date		: 13th August 2015
# Usage		: tg.pl stmfadm-list-tg-v.out
# Purpose	: Recreate the COMSTAR target group settings from a saved Collector file
# Version	: 0.02
# History	: 0.01 - Initial version
#		  0.02 - Now handles empty target groups and is smarter about offlining and onling the target
#

use strict;

my $num_args = $#ARGV + 1;

if ( $num_args < 1 ) {
    print "Usage: tg.pl stmfadm-list-tg-v.out\n";
    exit;
}

open (my $file, "<", $ARGV[0]) || die "Can't read file comstar target group file: $!";
my (@targetgroup_list) = <$file>;
close($file);

chomp(@targetgroup_list);
my ($targetgroup_lines) = scalar @targetgroup_list;
my $index = 0;

while ($index < $targetgroup_lines) {
    if ( $targetgroup_list[$index] =~ /Target Group:.+/ ) {
	my ($tag, $tg_name) = split /: /, $targetgroup_list[$index];
	printf("stmfadm create-tg %s\n", $tg_name);
	$index++;
        my ($member, $iqn) = split /: /, $targetgroup_list[$index];
        if ( $iqn ) {
	    printf("stmfadm offline-target %s\n", $iqn);
     	    while ( $targetgroup_list[$index] !~ /Target Group:.+/ && $index < $targetgroup_lines) {
                my ($member, $iqn) = split /: /, $targetgroup_list[$index];
                printf("stmfadm add-tg-member -g %s %s\n", $tg_name, $iqn);
	        $index++;
            }
            printf("stmfadm online-target %s\n", $iqn);
	    $index--;
        }
    }
    printf("\n");
    $index++;
}

