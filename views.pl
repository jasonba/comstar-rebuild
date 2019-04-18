#!/usr/bin/perl

#
# Name		: views.pl
# Author	: Jason Banham
# Date		: 13th August 2015 / 17th August 2015 / 1st September 2016 / 22nd March 2019
# Usage		: views.pl for-lu-in-stmfadm-list-lucut-d-f3-do-echo-echo-luecho-stmfadm-list-view-l-lu-done.out
# Purpose	: Recreate the COMSTAR views from a saved Collector file
# Version	: 0.04
# History	: 0.01 - Initial version
#		  0.02 - Added in checks for 'All' host group and target groups
#                 0.03 - Reworked the code to factor in an LU with multiple view entries as previous
#                        logic was very naive with respect to the format of the input file.
#                        (Thanks to Misha for finding the data file that caused the old logic to trip over)
#                 0.04 - Cluster switch code added
#

use strict;
use Getopt::Std;

my $cluster;
my $cmd = "stmfadm add-view";
my $local_cmd;

my $num_args = $#ARGV + 1;

if ( $num_args < 1 ) {
    print "Usage: views.pl for-lu-in-stmfadm-list-lucut-d-f3-do-echo-echo-luecho-stmfadm-list-view-l-lu-done.out\n";
    exit;
}

# declare the perl command line flags/options we want to allow
my %options=();
getopts("c", \%options);

if (defined $options{c}) {
    $cmd = "stmfha add-view";
}

open (my $file, "<", $ARGV[0]) || die "Can't read file: $ARGV[0]";
my (@view_list) = <$file>;
close($file);

chomp(@view_list);
my ($view_lines) = scalar @view_list;
my $index = 0;

$index = 1;     # First line is always blank

while ($index < $view_lines) {
    $local_cmd = "$cmd";
    if ($view_list[$index] =~ /^[0-6]*/) { 
        my $lu = $view_list[$index];
        $index ++;

        while ($view_list[$index] !~ /^[0-6]/ && $index < $view_lines) {
            if ($view_list[$index] =~ /Host group/) {
                $local_cmd = $cmd;
                my ($tag, $hg) = split /: /, $view_list[$index];
                if ($hg !~ /All/ ) {
	            $local_cmd = $local_cmd . " -h " . $hg;
                }
            }

            if ($view_list[$index] =~ /Target group/) {
                my ($tag, $tg) = split /: /, $view_list[$index];
                if ($tg !~ /All/ ) {
	            $local_cmd = $local_cmd . " -t " . $tg;
                }
            }

            if ($view_list[$index] =~ /LUN/) {
                my ($tag, $lun) = split /: /, $view_list[$index];
                $local_cmd = $local_cmd . " -n " . $lun . " " . $lu;
                printf("%s\n", $local_cmd);
            }
  
            $index++;
        }
    }
}
