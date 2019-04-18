#!/usr/bin/perl

#
# Name		: create-lu.pl
# Author	: Jason Banham
# Date		: 13th August 2015 / 17th August 2015 / 22nd January 2019 / 22nd March 2019
# Usage		: create-lu.pl stmfadm-list-lu-v.out
# Purpose	: Recreate the COMSTAR lus from a saved Collector file
# Version	: 0.04
# History	: 0.01 - Initial version
#		  0.02 - Now handles aliases and the management url data that may contain spaces
#                 0.03 - Now warns about LUs in standby mode and skips over them
#                 0.04 - Cluster switch code added
#

use strict;
use Getopt::Std;

my $cluster;
my $cmd = "stmfadm create-lu";

my $num_args = $#ARGV + 1;

if ( $num_args < 1 ) {
    print "Usage: create-lu.pl stmfadm-list-lu-v.out\n";
    exit;
}

# declare the perl command line flags/options we want to allow
my %options=();
getopts("c", \%options);

if (defined $options{c}) {
    $cmd = "stmfha create-lu";
}

open (my $file, "<", $ARGV[0]) || die "Can't read file: $ARGV[0]";
my (@lu_list) = <$file>;
close($file);

chomp(@lu_list);
my ($lu_lines) = scalar @lu_list;
my $index = 0;

#
# A logical unit can have a lot of properties [see stmfadm(1m) and logical-properties]
# so walk through the list that are documented according to the man page and build up
# a command line for each LU
#
while ($index < $lu_lines) {
    if ( $lu_list[$index] =~ /LU Name:/ ) {
	my ($tag, $guid) = split /: /, $lu_list[$index];
	my $cmd = $cmd . " -p guid=" . $guid;

	$index += 3;
	my ($tag, $alias) = split /:\s+/, $lu_list[$index];
	$cmd = $cmd . " -p alias=\"" . $alias . "\"";

	$index += 2;
	my ($tag, $datafile) = split /:\s+/, $lu_list[$index];

	$index++;
	my ($tag, $meta) = split /:\s+/, $lu_list[$index];
	if ( $meta !~ /not set/ ) {
	    $cmd = $cmd . " -p meta=" . $meta;
	}

	$index++;
	my ($tag, $size) = split /:\s+/, $lu_list[$index];

	$index++;
	my ($tag, $blksize) = split /:\s+/, $lu_list[$index];
	$cmd = $cmd . " -p blk=" . $blksize;

	$index++;
	my ($tag, $mgmturl) = split /:\s+/, $lu_list[$index];
	if ( $mgmturl !~ /not set/ ) {
	    $cmd = $cmd . " -p mgmt-url=\"" . $mgmturl . "\"";
	}
	
	$index++;
	my ($tag, $vendor) = split /:\s+/, $lu_list[$index];
	$cmd = $cmd . " -p vid=\"" . $vendor . "\"";

	$index++;
	my ($tag, $pid) = split /:\s+/, $lu_list[$index];
	$cmd = $cmd . " -p pid=\"" . $pid . "\"";

	$index++;
	my ($tag, $serialnum) = split /:\s+/, $lu_list[$index];
	if ( $serialnum !~ /not set/ ) {
	    $cmd = $cmd . " -p serial=" . $serialnum;
	}

	$index++;
	my ($tag, $wp) = split /:\s+/, $lu_list[$index];
	if ( $wp =~ /Enabled/ ) {
	    $cmd = $cmd . " -p wp=true"; 
	} else {
	    $cmd = $cmd . " -p wp=false";
	}

	$index++;
	my ($tag, $wcd) = split /:\s+/, $lu_list[$index];
	if ( $wcd =~ /Enabled/ ) {
	    $cmd = $cmd . " -p wcd=false";
	} else {
	    $cmd = $cmd . " -p wcd=true";
	}

        $index++;
        my ($tag, $state) = split /:\s+/, $lu_list[$index];
        if ( $state =~ /Standby/ ) {
            printf("\n\n### Unable to recreate GUID = %s (%s) as LU was in a standby state\n\n\n", $guid, $alias);
        } else {
	    $cmd = $cmd . " --size " . $size . " " . $datafile;
	    printf("%s\n", $cmd);
        }
    }
    $index++;
}

