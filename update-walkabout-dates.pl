#!/usr/bin/perl
#
# Usage:
#   update-walkabout-dates.pl input_file_to_be_edited_in_place.md
#
use strict;

undef $/;  # file slurp mode

my $infilename = shift @ARGV;

open IN, "<$infilename" or die "update-walkabout-dates.pl: couldn't open input <$infilename>\n";
my $in = <IN>;
close IN;

my ($daynum, $date);
foreach my $dayline ($in =~ /^(.*class\s*=\s*"day_source".*)/mg) {
  ($daynum, $date) = $dayline =~ /day_source"\s*>\s*(\d+).*\(([^)]+/;
  if ($havent_found_today) {
    # look for today
  } else {
    # look for and entry whose daynum is $future_daynum, and edit it.

    # edit contents
  }
}
