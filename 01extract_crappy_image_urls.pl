#!/usr/bin/perl

use strict;
use warnings;

my $dir = '/home/thunderrabbit/barefoot_rob_master/content/books'; # replace with the directory you want to search
my $url_prefix = 'https://b.robnugen.com/adaptive-images/ig_cache_2022_jan_17'; # replace with the URL prefix you want to match

my %urls; # create a hash to store unique URLs

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
                while ($line =~ m/"($url_prefix\S*\.jpg)"/g) {
                    $urls{$1} = 1; # add unique URLs that end with .jpg to the hash
                }
            }
            close($fh);
        }
    }
    closedir($dh);
}

# output unique URLs as an HTML file
open(my $html, '>', 'image_list.html') || die "Can't create HTML file: $!";
print $html "<html><body>\n";
foreach my $url (sort keys %urls) {
    print $html "<img src=\"$url\"><br>\n";
}
print $html "</body></html>\n";
close($html);
