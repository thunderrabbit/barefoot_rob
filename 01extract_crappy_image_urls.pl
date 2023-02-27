#!/usr/bin/perl

use strict;
use warnings;

my $dir = '/home/thunderrabbit/barefoot_rob_master/content/books'; # replace with the directory you want to search
my $url_prefix = 'https://b.robnugen.com/adaptive-images'; # replace with the URL prefix you want to match

process_directory($dir);

sub process_directory {
    my $dir = shift;
    opendir(my $dh, $dir) || die "Can't open directory $dir: $!";
    while (my $file = readdir($dh)) {
        next if ($file =~ m/^\./); # skip hidden files and directories
        my $path = "$dir/$file";
        if (-d $path) {
            process_directory($path); # recursively process subdirectories
        }
        elsif (-f $path) {
            open(my $fh, '<', $path) || die "Can't open file $path: $!";
            while (my $line = <$fh>) {
                while ($line =~ m/"($url_prefix\S*)"/g) {
                    print "$1\n";
                }
            }
            close($fh);
        }
    }
    closedir($dh);
}
