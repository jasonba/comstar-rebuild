#!/usr/bin/perl

#
# Name		: create-lu.pl
# Author	: Jason Banham
# Date		: 13th August 2015
# Usage		: create-lu.pl stmfadm-list-lu-v.out
# Purpose	: Recreate the COMSTAR lus from a saved Collector file
# Version	: 0.01
# History	: 0.01 - Initial version
#

use strict;

my $num_args = $#ARGV + 1;

if ( $num_args < 1 ) {
    print "Usage: create-lu.pl stmfadm-list-lu-v.out\n";
    exit;
}

open (my $file, "<", $ARGV[0]) || die "Can't read file numlist: $!";
my (@lu_list) = <$file>;
close($file);

chomp(@lu_list);
my ($lu_lines) = scalar @lu_list;
my $index = 0;

while ($index < $lu_lines) {
    if ( $lu_list[$index] =~ /LU Name:/ ) {
	my ($tag, $guid) = split /: /, $lu_list[$index];
	my $cmd = "stmfadm create-lu -p guid=" . $guid;

	$index += 3;
	my ($tag, $alias) = split /:\s+/, $lu_list[$index];
	$cmd = $cmd . " -p alias=" . $alias;

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
	    $cmd = $cmd . " -p mgmt-url=" . $mgmturl;
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

	$cmd = $cmd . " --size " . $size . " " . $datafile;
	printf("%s\n", $cmd);
    }
    $index++;
}

