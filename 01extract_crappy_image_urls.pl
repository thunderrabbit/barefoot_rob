#!/usr/bin/perl

use strict;
use warnings;
use File::Copy qw(move);

my $dir = '/home/thunderrabbit/barefoot_rob_master/content/books'; # replace with the directory you want to search
my $url_prefix = 'https://b.robnugen.com/adaptive-images/ig_cache_2022_jan_17'; # replace with the URL prefix you want to match
my $dest = "b.robnugen.com/quests/2021";

my %urls; # create a hash to store unique URLs
my @rename_commands; # create an array to store rename commands
my @image_list; # create an array to store unique URLs for HTML output
my $process_images = (-f "image_list.html");   # if we
my $create_image_list = !$process_images;
process_directory($dir);

sub process_directory {
    my $dir = shift;
    my $bail = 0;
    my $sanity = 0;
    opendir(my $dh, $dir) || die "Can't open directory $dir: $!";
    while (my $file = readdir($dh)) {
        next if ($file =~ m/^\./); # skip hidden files and directories
        last if $bail;
        my $path = "$dir/$file";
        if (-d $path) {
            process_directory($path); # recursively process subdirectories
        }
        elsif (-f $path) {
            my $content = ''; # store the modified content of the file
            my $modified = 0; # flag to indicate whether the file has been modified
            open(my $fh, '<', $path) || die "Can't open file $path: $!";
            while (my $line = <$fh>) {
                last if $bail;
                while ($line =~ m/"($url_prefix\S*\.jpg)"/g) {
                    my $url = $1;
                    unless ($urls{$url}) {
                        $urls{$url} = 1;
                        if($process_images)
                        {
                          my $new_filename = prompt_for_description($url);
                          $bail = !$new_filename;
                          last if $bail;
                          my $new_url = "$url_prefix/$new_filename";
                          $line =~ s/$url/$new_url/g;
                          $url =~ s/https:\/\//~\//; # replace "https://" with "~/"
                          push @rename_commands, "mv \"$url\" \"~/$dest/$new_filename.jpg\"\n";
                          $modified = 1;
                        } else {
                          $sanity++;
                          print $sanity . "\n";
                          $bail = $sanity >= 10;
                          push @image_list, $url;
                        }
                    }
                    last if $bail;
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

sub write_file {
    my ($filename, $content) = @_;
    open(my $fh, '>', $filename) || die "Can't write file $filename: $!";
    print $fh $content;
    close($fh);
}

if($create_image_list)
{
  # output unique URLs as an HTML file
  open(my $html, '>', 'image_list.html') || die "Can't create HTML file: $!";
  print $html "<html><body>\n";
  foreach my $url (sort keys %urls) {
      print $html "<img src=\"$url\"><br>\n";
  }
  print $html "</body></html>\n";
  close($html);
} else {
  open(my $fh, '>', 'commands.sh') or die "Can't open file 'commands.sh': $!";
  print $fh "#!/bin/bash\n";
  foreach my $command (@rename_commands) {
      print $fh "$command\n";
  }
  close($fh);
}
