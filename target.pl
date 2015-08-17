#!/usr/bin/perl

#
# Name		: target.pl
# Author	: Jason Banham
# Date		: 13th August 2015 / 17th August 2015
# Usage		: target.pl itadm-list-target-v.out
# Purpose	: Recreate the COMSTAR target settings from a saved Collector file
# Version	: 0.05
# History	: 0.01 - Initial version
#		  0.02 - Additional processing on IQN and AUTH to handle spacing and (defaults) after auth method
#	  	  0.03 - Now handles target portal tags
#		  0.04 - Now handles aliases with a hyphen in their name
#		  0.05 - Forgot to deal with chap username, now fixed.
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
	my ($target) = split /\s+/, $target_list[$index];
	$index++;
	my ($tag, $alias) = split /:\s+/, $target_list[$index];
	$index++;
	my ($tag, $auth) = split /:\s+/, $target_list[$index];
	my ($auth, $extra) = split /\s+/, $auth;
	$index++;
	my ($tag, $chapuser) = split /:\s+/, $target_list[$index];
	$index++;
	my ($tag, $chapsecret) = split /:\s+/, $target_list[$index];
	$index++;
	my ($tag, $tpgtags) = split /:\s+/, $target_list[$index];

        $tpgtags =~ s/ = [0-9]//g;
        my $cmd = "itadm create-target ";
        $cmd = $cmd . " -a " . $auth;

	if ( $alias !~ /^-$/ ) {
	    $cmd = $cmd . " -l \"" . $alias . "\"";
	}
	if ( $chapsecret !~ /unset/ ) {
	    $cmd = $cmd . " -s";
	}
	if ( $chapuser !~ /^-$/ ) {
	    $cmd = $cmd . " -u " . $chapuser;
	}
	if ( $tpgtags !~ /default/ ) {
	    $cmd = $cmd . " -t " . $tpgtags;
        }

	$cmd = $cmd . " -n " . $target;

	printf("%s\n", $cmd);
#     printf("itadm create-target -a %s -l %s -n %s\n", $auth, $alias, $target);
    }
    $index++;
}

