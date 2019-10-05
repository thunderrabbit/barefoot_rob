#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;			# explains why stuff is busted
use File::Slurp;

use File::Find;

my $dir = "/Users/thunderrabbit/journal/";
my $seen = 0;               # sanity checker

find(\&edits, $dir);        # I think this runs find on the directory and pushes it through edits()

sub edits() {

    # kill any files ending with ~
    if ( /~$/ ) {
        print "Deleting backup file: $File::Find::name\n";
        unlink $_;
        return;
    }

    my $edited = 0;
    if ($seen < 500000 and -f and /.md/ ) {
  #      print "Processing file: $File::Find::name\n";
        $seen++;
        $edited = 0;
        my $file = $_;
        open FILE, $file;
        my @lines = <FILE>;
        close FILE;
        for my $line ( @lines ) {

#  single tag, including spaces          if ( $line =~ /tags:\s*([\w ]*\w+)$/  ) {      # look for 'tags: tag, double tag, tag3, up, to, seven, tags' (with no quotes)
#  single tag              $line = "tags: [ \"$1\" ]\n";       # wrap tags with quotes and brackets

            if ( $line =~ /tags:\s+([^",]*),\s*([^",]*),\s*([^",]*),\s*([^",]*),\s*([^",]*),\s*([^",]*),\s*([^"\n,]*)$/  ) {      # look for 'tags: tag, double tag, tag3, up, to, seven, tags' (with no quotes)
                $edited = 1;
                print "$line\n";
                $line = "tags: [ \"$1\", \"$2\", \"$3\", \"$4\", \"$5\", \"$6\", \"$7\" ]\n";       # wrap tags with quotes and brackets
                print $line;
            }
#            if ( $line =~ /moment 1999 arrived/ ) {
#                print $File::Find::name;
#            }
        }
        if($edited) {
            open FILE, ">$file";                    # overwrite the same file
            print FILE @lines;                      # with the new lines
            close FILE;                             # save in place
        }
    }
    
}
