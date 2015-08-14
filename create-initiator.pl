#!/usr/bin/perl

#
# Name		: create-initiator.pl
# Author	: Jason Banham
# Date		: 13th August 2015
# Usage		: create-initiator.pl itadm-list-initiator-v.out
# Purpose	: Recreate the COMSTAR initiators from a saved Collector file
# Version	: 0.01
# History	: 0.01 - Initial version
#

use strict;

my $num_args = $#ARGV + 1;

if ( $num_args < 1 ) {
    print "Usage: create-initiator.pl itadm-list-initiator-v.out\n";
    exit;
}

open (my $file, "<", $ARGV[0]) || die "Can't read file numlist: $!";
my (@initiator_list) = <$file>;
close($file);

chomp(@initiator_list);
my ($initiator_lines) = scalar @initiator_list;
my $index = 0;

while ($index < $initiator_lines) {
    if ( $initiator_list[$index] =~ /iqn\./ ) {
	my ($iqn, $chapuser, $chapsecret) = split /\s+/, $initiator_list[$index];	
	my $cmd = "itadm create-initiator";

	if ( $chapuser !~ /<none>/ ) {
	    $cmd = $cmd . " -u " . $chapuser;
	}

	if ( $chapsecret !~ /unset/ ) {
	    $cmd = $cmd . " -s";
	}

	$cmd = $cmd . " " . $iqn;
	printf("%s\n", $cmd);
    }
    $index++;
}

