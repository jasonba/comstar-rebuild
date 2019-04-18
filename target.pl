#!/usr/bin/perl

#
# Name		: target.pl
# Author	: Jason Banham
# Date		: 13th August 2015 / 17th August 2015 / 22nd March 2019 / 18th April 2019
# Usage		: target.pl itadm-list-target-v.out
# Purpose	: Recreate the COMSTAR target settings from a saved Collector file
# Version	: 0.08
# History	: 0.01 - Initial version
#		  0.02 - Additional processing on IQN and AUTH to handle spacing and (defaults) after auth method
#	  	  0.03 - Now handles target portal tags
#		  0.04 - Now handles aliases with a hyphen in their name
#		  0.05 - Forgot to deal with chap username, now fixed.
#		  0.06 - Now handles target aliases with spaces in the name
#                 0.07 - Cluster switch code added
#                 0.08 - CHAP secret accepted as an argument
#

use strict;
use Getopt::Std;

my $cluster;
my $cmd = "itadm";
my $local_cmd;
my $secret = "TARGET_SECRET";

my $num_args = $#ARGV + 1;

if ( $num_args < 1 ) {
    print "Usage: target.pl itadm-list-target-v.out\n";
    exit;
}

# declare the perl command line flags/options we want to allow
my %options=();
getopts("cs:", \%options);

if (defined $options{c}) {
    $cmd = "stmfha";
}

if (defined $options{s}) {
    $secret = $options{s};
}
    
open (my $file, "<", $ARGV[0]) || die "Can't read file: $ARGV[0]";
my (@target_list) = <$file>;
close($file);

chomp(@target_list);
my ($target_lines) = scalar @target_list;
my $index = 0;

while ($index < $target_lines) {
    $local_cmd = "$cmd";
    if ( $target_list[$index] =~ /iqn.+/ ) {
	my ($target) = split /\s+/, $target_list[$index];
	$index++;

	my ($tag, $alias) = split /:\s+/, $target_list[$index];
	$index++;

        #
	# An auth line may look like:
	# 	auth:               	none 
	#	auth:               	chap 
	#	auth:               	none (defaults)
	#
	# We seperate the auth: label from the auth type but sometimes we may need
	# to then strip off the extra guff afterwards.
	#
	my ($tag, $auth) = split /:\s+/, $target_list[$index];
	my ($auth, $extra) = split /\s+/, $auth;
	$index++;

	my ($tag, $chapuser) = split /:\s+/, $target_list[$index];
	$index++;

	my ($tag, $chapsecret) = split /:\s+/, $target_list[$index];
	$index++;

	#
	# The itadm output shows tpg tags like this:
	#	tpg-tags:           	tpg1 = 3,tpg2 = 2
	#	tpg-tags:           	default
	#	tpg-tags:           	Ixgbe0 = 2
	#
	# The '= count' is additional cruff we don't require to build the config
	# so we have to strip that out to get something usable.
	#
	my ($tag, $tpgtags) = split /:\s+/, $target_list[$index];
        $tpgtags =~ s/ = [0-9]//g;

#        my $cmd = "itadm create-target ";
        $local_cmd = $cmd . " create-target -a " . $auth;

	if ( $alias !~ /^-$/ ) {
	    $local_cmd = $local_cmd . " -l \"" . $alias . "\"";
	}
	if ( $chapsecret !~ /unset/ ) {
	    $local_cmd = $local_cmd . " -s " . $secret;
	}
	if ( $chapuser !~ /^-$/ ) {
	    $local_cmd = $local_cmd . " -u " . $chapuser;
	}
	if ( $tpgtags !~ /default/ ) {
	    $local_cmd = $local_cmd . " -t " . $tpgtags;
        }

	$local_cmd = $local_cmd . " -n " . $target;

	printf("%s\n", $local_cmd);
    }
    $index++;
}

