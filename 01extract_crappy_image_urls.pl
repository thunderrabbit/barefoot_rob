#!/usr/bin/perl

use strict;
use warnings;
use File::Copy qw(move);

my $dir = '/home/thunderrabbit/barefoot_rob_master/content/books'; # replace with the directory you want to search
my $url_prefix = 'https://b.robnugen.com/adaptive-images/ig_cache_2022_jan_17'; # replace with the URL prefix you want to match

my %urls; # create a hash to store unique URLs
my @rename_commands; # create an array to store rename commands
my @image_list; # create an array to store unique URLs for HTML output

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
            my $content = ''; # store the modified content of the file
            my $modified = 0; # flag to indicate whether the file has been modified
            open(my $fh, '<', $path) || die "Can't open file $path: $!";
            while (my $line = <$fh>) {
                while ($line =~ m/"($url_prefix\S*\.jpg)"/g) {
                    my $url = $1;
                    unless ($urls{$url}) {
                        $urls{$url} = 1;
                        my $new_filename = prompt_for_description($url);
                        my $new_url = "$url_prefix/$new_filename";
                        $line =~ s/$url/$new_url/g;
                        push @rename_commands, "mv \"$url\" \"~/$new_filename\"\n";
                        move_file($url, $new_filename);
                        $modified = 1;
                        push @image_list, $new_url;
                    }
                }
                $content .= $line;
            }
            close($fh);
            if ($modified) {
                write_file($path, $content);
            }
        }
    }
    closedir($dh);
}

sub prompt_for_description {
    my $url = shift;
    my ($filename) = $url =~ m/\/([^\/]+)$/; # extract the filename from the URL
    my $new_filename = prompt("Enter description for $filename: ");
    $new_filename =~ s/[^a-zA-Z0-9_.-]/_/g; # replace invalid characters with underscores
    return $new_filename;
}

sub prompt {
    my $prompt = shift;
    print $prompt;
    my $input = <STDIN>;
    chomp $input;
    return $input;
}

sub move_file {
    my ($old_filename, $new_filename) = @_;
    $old_filename =~ s/https:\/\//~\//; # replace "https://" with "~/"
    $new_filename =~ s/https:\/\//~\//; # replace "https://" with "~/"
    move($old_filename, $new_filename) || die "Can't move file $old_filename to $new_filename: $!";
}

sub write_file {
    my ($filename, $content) = @_;
    open(my $fh, '>', $filename) || die "Can't write file $filename: $!";
    print $fh $content;
    close($fh);
}

# output unique URLs as an HTML file
open(my $html, '>', 'image_list.html') || die "Can't create HTML file: $!";
print $html "<html><body>\n";
foreach my $url (sort keys %urls) {
    print $html "<img src=\"$url\"><br>\n";
}
print $html "</body></html>\n";
close($html);
