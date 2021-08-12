#!/usr/bin/perl

use strict;

# https://stackoverflow.com/a/46550384/194309
use Cwd qw( abs_path );
use File::Basename qw( dirname );
use lib dirname(abs_path(__FILE__));
use rpl::Constants;
use rpl::Functions;

my $verbosity = 10; # integer from 0 (silent) to 5 (all the debugging info).

my $what_kinda_event = rpl::Functions::get_event_type("Event Types", sort keys %rpl::Constants::event_template_files);

my $event_template_file = $rpl::Constants::event_template_files{$what_kinda_event};

my $title_image = "";   ## Getting this via $ARGV[0]..  not sure how else makes sense to get it

#######################################################3#######################################################3
# THIS IS TO MAKE BLOG ENTRIES BASED ON EVENTS
#
# load latest files from events directory
# look for files which contain a line including "tags" and "mmm"
# ask which file to pull data from
# EVENT_FILE = slurp file user selects from list
# $blog_date = get date from user, default to most recent Monday
# create BLOGFILE:
## BLOGFILE = copy  EVENT_FILE to $blog_directory/(YYYY/MM/ $blog_date)/(DD $blog_date)(remove first two digits from (EVENT_FILE basename) keep the rest of basename)
## (NOOP): keep same title and tags
## change date in frontmatter to match $blog_date  (see below "# handle date separately")
## remove line starting with EventTime
## remove line starting with EventDate
## remove lines after (frontmatter (second occurence of ---) and optional image (begins with "<img")) up until "#### Details"
# append body with "If this sounds like something that would interest you, contact me, email me, find me so we can talk."
#
#######################################################3#######################################################3

# Get input data from commands
# TODO: error handling
#
my $event_template;

{
  # debug interface just to get the bulk of the code working

  local $/;  # makes changes local to this block
  undef $/;  # file slurp mode (default is "\n")
  open (ETF, "<", $event_template_file);

  $event_template = <ETF>;

  close ETF;
}

if ($verbosity > 2) {
  print "length(ETF) = " . length($event_template) . "\n";
}

my $number_args = $#ARGV + 1;
if ($number_args == 0) {
    print "Feel free to send images as arguments.\n";
}

# Do the same for episodes as we did for frames.
# Because we don't have to monkey with the $id here,
# we can do the whole thumbs loop in one line.
my @episode_images = @ARGV;
my @episode_thumbs = map { m{(.*)/([^/]+)}; "$1/thumbs/$2" } @episode_images;

## BUILD OUTPUT
#
my $new_entry;

my ($event_date_time) = rpl::Functions::get_date($rpl::Functions::dt);

my $title = rpl::Functions::get_title($rpl::Constants::event_title_prefixes{$what_kinda_event});

my $tagstring = rpl::Functions::get_tags(%{$rpl::Constants::event_tag_hashes{$what_kinda_event}});  # returns qq/"mt3", "livestream", "maybe_others"/
my ($episode_image,$episode_thumb) = rpl::Functions::get_episode_image($title, @episode_images, @episode_thumbs);

$new_entry->{title} = $title;
$new_entry->{tags} = $tagstring;
$new_entry->{EventDate} = $event_date_time->ymd;
# now build the output!
my $mt3_episode_output = $event_template;

# handle date separately
$mt3_episode_output =~ s/^(date: .*)/date: $rpl::Functions::tz_date/im;
my $human_date = $event_date_time->strftime("%A %d %B %Y");
$mt3_episode_output =~ s/human_date_here/$human_date/;
$mt3_episode_output =~ s/episode_image/$episode_image/;
# do the rest algorithmically
foreach my $key (keys %{ $new_entry }) {
  my $value = $new_entry->{$key};
  $mt3_episode_output =~ s/^(\Q$key\E: .*?)%s(.*)/$1$value$2/im;
}# $k


# store this for debugging
$new_entry->{mt3_episode_output} = $mt3_episode_output;

# Create outfile path based on today's date
# convention: the deepest directories are months, not days, so day is part of base filename, e.g. /yyyy/mm/ddtitle.md
my %event_output_directories = (
    "blog_entry" => $rpl::Constants::blog_directory . "/" . $rpl::Functions::dt->ymd("/"),             # don't end with slash, by `convention` above
    "book_chapter" => $rpl::Constants::slow_down_book_dir . "/" . $event_date_time->ymd . "_",   # don't end with slash because book directories have no dates
    "weekly_alignment" => $rpl::Constants::events_directory . "/" . $event_date_time->ymd("/"),     # don't end with slash, by `convention` above
    "walking_meditation" => $rpl::Constants::events_directory . "/" . $event_date_time->ymd("/"),   # don't end with slash, by `convention` above
    "quest_update" => $rpl::Constants::niigata_walk_dir . "/" . $rpl::Functions::dt->ymd("/"),         # don't end with slash, by `convention` above
);

my $alias_path = $event_output_directories{$what_kinda_event};
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
