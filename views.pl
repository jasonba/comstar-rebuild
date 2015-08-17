#!/usr/bin/perl

#
# Name		: views.pl
# Author	: Jason Banham
# Date		: 13th August 2015 / 17th August 2015
# Usage		: views.pl for-lu-in-stmfadm-list-lucut-d-f3-do-echo-echo-luecho-stmfadm-list-view-l-lu-done.out
# Purpose	: Recreate the COMSTAR views from a saved Collector file
# Version	: 0.02
# History	: 0.01 - Initial version
#		  0.02 - Added in checks for 'All' host group and target groups
#

use strict;

my $num_args = $#ARGV + 1;

if ( $num_args < 1 ) {
    print "Usage: views.pl for-lu-in-stmfadm-list-lucut-d-f3-do-echo-echo-luecho-stmfadm-list-view-l-lu-done.out\n";
    exit;
}

open (my $file, "<", $ARGV[0]) || die "Can't read file : $!";
my (@view_list) = <$file>;
close($file);

chomp(@view_list);
my ($view_lines) = scalar @view_list;
my $index = 0;
my $cmd = "";

while ($index < $view_lines) {
    $cmd = "stmfadm add-view";
    $index++;		# First line is always blank
    my $lu = $view_list[$index];

    $index += 3;	# Skip over the next blank line and the view entry

    my ($tag, $hg) = split /: /, $view_list[$index];
    if ($hg !~ /All/ ) {
	$cmd = $cmd . " -h " . $hg;
    }
    $index++;

    my ($tag, $tg) = split /: /, $view_list[$index];
    if ($tg !~ /All/ ) {
	$cmd = $cmd . " -t " . $tg;
    }
    $index++;

    my ($tag, $lun) = split /: /, $view_list[$index];
    $cmd = $cmd . " -n " . $lun . " " . $lu;
  
    printf("%s\n", $cmd);
 
    $index++;
}
