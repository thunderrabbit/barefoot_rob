#!/usr/bin/perl

use strict;

# https://stackoverflow.com/a/46550384/194309
use Cwd qw( abs_path );
use File::Basename qw( dirname );
use lib dirname(abs_path(__FILE__));
use rpl::Constants;
use rpl::Functions;

my $verbosity = 10; # integer from 0 (silent) to 5 (all the debugging info).

# load latest files from events directory    find content/events/2021/ | sort -r | grep $(date +%Y/%m)
my @event_list_for_month = rpl::Functions::get_list_of_files_in_dir($rpl::Constants::content_directory . $rpl::Constants::events_directory . "/2021/08");

# ask which file to pull data from
my $event_file_to_blog = rpl::Functions::get_event_type("Events", @event_list_for_month);   # func get_event_type is generic, but misnamed here

print rpl::Functions::strip_path($event_file_to_blog) . "\n";

#######################################################3#######################################################3
# BEGIN MAKE BLOG ENTRIES BASED ON EVENTS
#######################################################3#######################################################3

# Slurp the event file
# TODO: error handling
#
my $blog_template;

{
  # EVENT_FILE = slurp file user selects from list
  local $/;  # makes changes local to this block
  undef $/;  # file slurp mode (default is "\n")
  open (ETF, "<", $event_file_to_blog);

  $blog_template = <ETF>;

  close ETF;
}

$blog_template =~ /(title: ")([^"]+)(")/;
my $blog_title = $2;
print "TITLE $blog_title\n";

# get event date from frontmatter (make blog date the same date as the event was)
$blog_template =~ /(EventDate: ")([^"]+)(")/;               # get date from frontmatter
my ($blog_year, $blog_month, $blog_day) = split("-",$2);    # $2 expected format yyyy-mm-dd
print "DATE $blog_year $blog_month $blog_day\n";

## Make sure date looks reasonable
unless ($blog_year =~ m/^\d{4}$/ && $blog_month =~ m/^\d{2}$/ && $blog_day =~ m/^\d{2}$/) {   #https://stackoverflow.com/a/6697134/194309
    print "Seems like the date we got from the event doesn't look like a date. $blog_year年$blog_month月$blog_day日\n";
    exit(1); ## tells the caller side that there is an error
}


my $blog_frontmatter = rpl::Functions::extract_frontmatter($blog_template);

# process frontmatter
## (NOOP): keep same title and tags

## change date in frontmatter to match current date
$blog_frontmatter =~ s/^(date: .*)/date: $rpl::Functions::tz_date/im;

## frontmatter remove line starting with EventTime (only used on events, not blog entry after the fact)
$blog_frontmatter =~ s/^(EventTime: .*\n)//im;     # Fred, is there a way to not need to \n in the capture we are erasing?

## frontmatter remove line starting with EventDate (only used on events, not blog entry after the fact)
$blog_frontmatter =~ s/^(EventDate: .*\n)//im;     # Fred, is there a way to not need to \n in the capture we are erasing?


my $blog_body = rpl::Functions::wipe_frontmatter($blog_template);

# process body
## Split on the #### title bits

my @body_parts = rpl::Functions::split_body("####", $blog_body);


## before first #### is the image
## Process image section
### Ask if user wants to update image to one sent on CLI   (see generate_events.pl for ideas)
### Update image if so
my $image_section = $body_parts[0];



# foreach (@body_parts) {
#   print "body part $_ \n\n\n";
# }


## remove lines after (frontmatter (second occurence of ---) and optional image (begins with "<img")) up until "#### Details"
### remove #### When block
### remove #### Where block
# append body with "If this sounds like something that would interest you, contact me, email me, find me so we can talk."
# determine $blog_outfile_name $blog_directory/(YYYY/MM/ $blog_date)/(DD $blog_date)kebab_case title
# BLOGFILE = write to $blog_outfile_name
#

# create BLOGFILE:

print "---\n";
print $blog_frontmatter . "\n";
print "---\n";
print "$image_section\n";

exit;

# Do the same for episodes as we did for frames.
# Because we don't have to monkey with the $id here,
# we can do the whole thumbs loop in one line.
my @episode_images = @ARGV;
my @episode_thumbs = map { m{(.*)/([^/]+)}; "$1/thumbs/$2" } @episode_images;

## BUILD OUTPUT
#
my $new_entry;


my $title = ""; #rpl::Functions::get_title($rpl::Constants::event_title_prefixes{$what_kinda_event});

my $tagstring = ""; # rpl::Functions::get_tags(%{$rpl::Constants::event_tag_hashes{$what_kinda_event}});  # returns qq/"mt3", "livestream", "maybe_others"/
my ($episode_image,$episode_thumb) = rpl::Functions::get_episode_image($title, @episode_images, @episode_thumbs);

$new_entry->{title} = $title;
$new_entry->{tags} = $tagstring;
# now build the output!
my $mt3_episode_output = $blog_template;

# handle date separately
$mt3_episode_output =~ s/^(date: .*)/date: $rpl::Functions::tz_date/im;
$mt3_episode_output =~ s/%episode_image/$episode_image/;
# do the rest algorithmically
foreach my $key (keys %{ $new_entry }) {
  my $value = $new_entry->{$key};
  $mt3_episode_output =~ s/^(\Q$key\E: .*?)%s(.*)/$1$value$2/im;
}# $k


# store this for debugging
$new_entry->{mt3_episode_output} = $mt3_episode_output;

#######################################################3#######################################################3
# END MAKE BLOG ENTRIES BASED ON EVENTS
#######################################################3#######################################################3

# Create outfile path based on today's date
# convention: the deepest directories are months, not days, so day is part of base filename, e.g. /yyyy/mm/ddtitle.md
my %event_output_directories = (
    "blog_entry" => $rpl::Constants::blog_directory . "/" . $rpl::Functions::dt->ymd("/"),             # don't end with slash, by `convention` above
);

my $alias_path = ""; # $event_output_directories{$what_kinda_event};
my $title_path = rpl::Functions::kebab_case($title);
my $outfile_path = $rpl::Constants::content_directory . $alias_path;   # oh, this includes the dd part of the filename (ddtitle.md)
my $outfile_and_title_path = $outfile_path . $title_path . ".md";

my $dirname_of_output_file = dirname($outfile_and_title_path);
mkdir($dirname_of_output_file);     # TODO consider File::Path  https://stackoverflow.com/a/701494/194309

$mt3_episode_output =~ s|alias_path|$alias_path$title_path|;

open(OUT, ">", $outfile_and_title_path) or die "Could not open file '$outfile_and_title_path'";
print OUT $mt3_episode_output;
close(OUT);

print "+---------------------------------+\n";
print "| wrote to $outfile_and_title_path\n";
print "+---------------------------------+\n";


# DONE!
