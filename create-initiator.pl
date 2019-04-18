#!/usr/bin/perl

#
# Name		: create-initiator.pl
# Author	: Jason Banham
# Date		: 13th August 2015 | 22nd March 2019 | 18th April 2019
# Usage		: create-initiator.pl itadm-list-initiator-v.out
# Purpose	: Recreate the COMSTAR initiators from a saved Collector file
# Version	: 0.03
# History	: 0.01 - Initial version
#                 0.02 - Cluster switch code added
#                 0.03 - CHAP secret accepted as an argument
#

use strict;
use Getopt::Std;

my $cluster;
my $cmd = "itadm create-initiator";
my $local_cmd;
my $secret = "INITIATOR_SECRET";

my $num_args = $#ARGV + 1;

if ( $num_args < 1 ) {
    print "Usage: create-initiator.pl [ -s <chap_secret> ] itadm-list-initiator-v.out\n";
    exit;
}

# declare the perl command line flags/options we want to allow
my %options=();
getopts("cs:", \%options);

if (defined $options{c}) {
    $cmd = "stmfha create-initiator";
}

if (defined $options{s}) {
    $secret = $options{s};
}

open (my $file, "<", $ARGV[0]) || die "Can't read file: $ARGV[0]";
my (@initiator_list) = <$file>;
close($file);

chomp(@initiator_list);
my ($initiator_lines) = scalar @initiator_list;
my $index = 0;

while ($index < $initiator_lines) {
    $local_cmd = $cmd;
    if ( $initiator_list[$index] =~ /iqn\./ ) {
	my ($iqn, $chapuser, $chapsecret) = split /\s+/, $initiator_list[$index];	

	if ( $chapuser !~ /<none>/ ) {
	    $local_cmd = $cmd . " -u " . $chapuser;
	}

	if ( $chapsecret !~ /unset/ ) {
            $local_cmd = $local_cmd . " -s " . $secret;
	}

	$local_cmd = $local_cmd . " " . $iqn;
	printf("%s\n", $local_cmd);
    }
    $index++;
}

