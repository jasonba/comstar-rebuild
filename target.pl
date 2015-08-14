#!/usr/bin/perl

#
# Name		: target.pl
# Author	: Jason Banham
# Date		: 13th August 2015
# Usage		: target.pl itadm-list-target-v.out
# Purpose	: Recreate the COMSTAR target settings from a saved Collector file
# Version	: 0.01
# History	: 0.01 - Initial version
#

use strict;

my $num_args = $#ARGV + 1;

if ( $num_args < 1 ) {
    print "Usage: target.pl itadm-list-target-v.out\n";
    exit;
}

open (my $file, "<", $ARGV[0]) || die "Can't read file numlist: $!";
my (@target_list) = <$file>;
close($file);

chomp(@target_list);
my ($target_lines) = scalar @target_list;
my $index = 0;

while ($index < $target_lines) {
    if ( $target_list[$index] =~ /iqn.+/ ) {
	my ($target) = split / /, $target_list[$index];
	$index++;
	my ($tag, $alias) = split /:\s+/, $target_list[$index];
	$index++;
	my ($tag, $auth) = split /:\s+/, $target_list[$index];
	$index++;
	my ($tag, $chapuser) = split /:\s+/, $target_list[$index];
	$index++;
	my ($tag, $chapsecret) = split /:\s+/, $target_list[$index];
	$index++;
	my ($tag, $tpgtags) = split /:\s+/, $target_list[$index];
        my $cmd = "itadm create-target ";
        $cmd = $cmd . " -a " . $auth;

	if ( $alias !~ /-/ ) {
	    $cmd = $cmd . " -l " . $alias;
	}
	if ( $chapsecret !~ /unset/ ) {
	    $cmd = $cmd . " -s";
	}
	$cmd = $cmd . " -n " . $target;

	printf("%s\n", $cmd);
#     printf("itadm create-target -a %s -l %s -n %s\n", $auth, $alias, $target);
    }
    $index++;
}

