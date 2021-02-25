#!/usr/bin/perl

use strict;
use Data::Dumper;
use DateTime;

my $verbosity = 10; # integer from 0 (silent) to 5 (all the debugging info).

my $zone = "Asia/Tokyo";
my $zoffset = "+09:00";

my $dt = DateTime->now(
    time_zone  => $zone,
);

my $thedate = $dt->ymd;  # year-month-date (numeric).
my $thetime = $dt->hms;  # hour-min-sec    (numeric).
my $year    = $dt->year;
my $month   = $dt->month;
my $day     = $dt->day;

my $event_template_file = "/home/thunderrabbit/.emacs.d/modes/hugo/templates/event_weekly-alignment_template.txt";
my $content_directory = "/home/thunderrabbit/barefoot_rob/content";
my $blog_directory = "$content_directory/blog";
my $events_directory = "$content_directory/events";

# load latest files from events directory

# look for files which contain a line including "tags" and "mmm"

# ask which file to pull data from

# EVENT_FILE = slurp file user selects from list

# $blog_date = get date from user, default to most recent Monday

# create BLOGFILE:

# BLOGFILE = copy  EVENT_FILE to $blog_directory/(YYYY/MM/ $blog_date)/(DD $blog_date)(remove first two digits from (EVENT_FILE basename) keep the rest of basename)
# (NOOP): keep same title and tags
# change date in frontmatter to match $blog_date  (see below "# handle date separately")
# remove line starting with EventTime
# remove line starting with EventDate
# remove lines after (frontmatter (second occurence of ---) and optional image (begins with "<img")) up until "#### Details"

# append body with "If this sounds like something that would interest you, contact me, email me, find me so we can talk."


# Get input data from commands
# TODO: error handling
#
my $event_template;
my $bframes_output;
my $known_videos_diff;

my $run_live = 0;
if ($run_live) {
  local $/;  # makes changes local to this block
  undef $/;  # file slurp mode (default is "\n")

  open (ETF,"<".$event_template_file);
  $event_template = <ETF>;
  close ETF;

  $bframes_output = `cd ~/mt3; ./bframes.sh`;
  $known_videos_diff = `cd ~/mt3.com; ./deploy.sh; git diff data/playlists/knownvideos.toml`;

} else {
  # debug interface just to get the bulk of the code working

  local $/;  # makes changes local to this block
  undef $/;  # file slurp mode (default is "\n")
  open (ETF,"<".$event_template_file);

  $event_template = <ETF>;

  close ETF;
}# $run_live

if ($verbosity > 2) {
  print "length(ETF) = " . length($event_template) . "\n";
}

## PROCESS BFRAMES_OUTPUT
#
# Notes:
#   1. We do not explicitly handle the case of two different new videos.
#      I have a thought of how to do this slightly cleverly.
#      BUT!  The current one-video assumption is not bad.
#      If there are multiple videos:
#        - It will add all the frames to all the videos,
#          meaning the user has to hand-delete the extra frames.
#        - The user will have to pick from a longer list for thumbnails.
#          Probably this will not cause difficulty.
#
#   2. We make assumptions of what the filenames look like.
#      episodes: b.robnugen.com/path/to/track/parts/more/path/filename.jpg
#      images: //b.robnugen.com/path/to/frames/more/stuff/filename.jpg
#      thumbs: //b.robnugen.com/all/the/same/but/add/thumbs/as/bottom/subdir/filename.jpg
#
my $frameout = "";
my @frames = $bframes_output =~ m{(//b.robnugen.com .* /frames/ .* jpg)}xig;

foreach my $frame (@frames) {
  my ($id) = $frame =~ m{([^/]+).jpg};
      $id  =~ s/_/ /g;  # convert all _ to space

  my $thumb = "$1/thumbs/$2" if $frame =~ m{(.*)/([^/]+)};

  $frameout .= "[![$id]($thumb)]($frame)\n";
}# $frame

# Do the same for episodes as we did for frames.
# Because we don't have to monkey with the $id here,
# we can do the whole thumbs loop in one line.
my @episode_images = $bframes_output =~ m{(https://b.robnugen.com .* /track/parts/ .* jpg)}xig;
my @episode_thumbs = map { m{(.*)/([^/]+)}; "$1/thumbs/$2" } @episode_images;


## BUILD OUTPUT
#
my $new_entry;
my $title = get_title();

my ($event_date, $event_date_human) = get_date($dt);
my $tagstring = get_tags();  # returns qq/"mt3", "livestream", "maybe_others"/
my ($episode_image,$episode_thumb) = get_episode_image();

$new_entry->{title} = $title;
$new_entry->{tags} = $tagstring;
$new_entry->{episode_image} = $episode_image;
$new_entry->{episode_thumbnail} = $episode_thumb;
$new_entry->{EventDate} = $event_date;
# now build the output!
my $mt3_episode_output = $event_template;

# handle date separately
$mt3_episode_output =~ s/^(date: .*)/date: $event_date/im;
$mt3_episode_output =~ s/human_date_here/$event_date_human/;
# do the rest algorithmically
foreach my $key (keys %$new_entry) {
  my $value = $new_entry->{$key};
  $mt3_episode_output =~ s/^(\Q$key\E: .*?)%s(.*)/$1$value$2/im;
}# $k


# append images
$mt3_episode_output .= "Here are the frames taken today:\n\n";  # should this go in the template?
$mt3_episode_output .= $frameout;

# store this for debugging
$new_entry->{mt3_episode_output} = $mt3_episode_output;

# TODO: Write the final output to a file.
print "+---------------------------------+\n";
print "| file.md output:                 |\n";
print "+---------------------------------+\n";
print $mt3_episode_output;


# DONE!
# END MAIN()
# SUBROUTINES FOLLOW
sub get_title($)
{
  my $confirmed = 0;
  my $title;
  my $prefix = "Weekly Alignments - ";
  while (!$confirmed) {
    $title = <STDIN>;
    $title =~ s/\s+/ /g;       # two spaces => one space
    $title =~ s/^\s+|\s+$//g;  # strip surrounding whitespace
    $title =~ s/^"(.*)"$/$1/;  # strip surrounding "s
    $title =~ s/^\s+|\s+$//g;  # strip surrounding whitespace  }
    $title = $prefix.$title;
    print "\nIs this title string correct?  (y/n)\n";
    print "  $title\n";
    while (1) {
      my $resp = <STDIN>;
      $resp =~ s/^\s+|\s+$//g;

      if    ($resp =~ /^y/i) { $confirmed = 1; last; }
      elsif ($resp =~ /^n/i) { $confirmed = 0; last; }
      else  {
        print "Please answer \"yes\" or \"no\".  ";
      }
    }# while confirm tags
  }
  return $title;
}

sub get_date($) {
  my ($dt) = (@_);
  my $desired_day_of_week = 4;  # Thursday
  print "in get date.   TODO: let us choose which upcoming Thursday to use.... \n";
  my $days_until_coming_thursday = ($desired_day_of_week + 7 - $dt->day_of_week) % 7;  #  https://codereview.stackexchange.com/a/33648/5794
  print $dt->day_of_week . "\n";
  print $days_until_coming_thursday . "\n";
  print "leavin get date\n";
  $dt->add( days => $days_until_coming_thursday );
  return ($dt->ymd, $dt->strftime("%A %d %B %Y"));
}

sub get_tags($) {
  my $confirmed = 0;
  my $tagstring;


  while (!$confirmed) {
    # put the tags in a hash
    my %tags = ("weekly" => 1, "alignment" => 1, "event" => 1);

    print "\n";
    print "Please enter tags for the post.\n";
    print "Enter a blank line to complete entry.\n";
    print "Prepend a tag with - to remove.\n";

    # read tags
    while (1) {
      $tagstring = join ', ', map { "\"$_\"" } sort keys %tags;  # <------ $tagstring set here
      print "Current tag list: [ $tagstring ]\n";

      my $newtagstring = <STDIN>;
         $newtagstring =~ s/\s+/ /g;       # two spaces => one space
         $newtagstring =~ s/^\s+|\s+$//g;  # strip surrounding whitespace
         $newtagstring =~ s/^"(.*)"$/$1/;  # strip surrounding "s
         $newtagstring =~ s/^\s+|\s+$//g;  # strip surrounding whitespace

      # DONE entering tags if user typed nothing
      last if !length($newtagstring);

      # make lists of the good tags and the bad tags
      my @newtaglist = split /\s*,\s*/, $newtagstring;
      my @goodtaglist = grep { /^[^-]/ } @newtaglist;
      my @badtaglist = map { s/^-//; $_ } grep { /^-/ } @newtaglist;

      @tags{ @newtaglist } = 1;     # add all the tags (ignores redundant tags)
      delete @tags{ @badtaglist };  # delete the bad tags

    }# while read tags

    # confirm tags
    print "\nIs this tag string correct?  (yes/no)\n";
    print "  $tagstring\n";
    while (1) {
      my $resp = <STDIN>;
         $resp =~ s/^\s+|\s+$//g;

      if    ($resp =~ /^y/i) { $confirmed = 1; last; }
      elsif ($resp =~ /^n/i)  { $confirmed = 0; last; }
      else  {
        print "Please answer \"yes\" or \"no\".  ";
      }
    }# while confirm tags

  }# !$confirmed

  return $tagstring;
}# get_tags()



sub get_episode_image($) {
  my ($new_entry) = (@_);
  my $confirmed = 0;
  my ($episode_image,$episode_thumb);

  while (!$confirmed) {

    print "\n";
    print "Please select the episode image for the following video:\n";
    print "  title:     $new_entry->{title}\n";
    print "  youtubeID: $new_entry->{youtube}\n";
    print "  published: $new_entry->{published}\n";
    print "  duration:  $new_entry->{duration}\n";
    print "\n";

    my $num_episode_images = scalar(@episode_images);
    foreach my $ii (1..$num_episode_images) {
      my $iipad = " " x (length($num_episode_images) - length($ii));
      print "$iipad($ii) $episode_images[$ii-1] $iipad($ii)\n";
    }# $ii

    print "Enter the number of the image you want to select: ";
    my $jj = <STDIN>;

    $episode_image = $episode_images[$jj-1];
    $episode_thumb = $episode_thumbs[$jj-1];

    # confirm selected image
    print "\nIs this episode image correct?  (yes/no)\n";
    print "  episode_image:     $episode_image\n";
    print "  episode_thumbnail: $episode_thumb\n";

    while (1) {
      my $resp = <STDIN>;
         $resp =~ s/^\s+|\s+$//g;

      if    ($resp =~ /^y/i) { $confirmed = 1; last; }
      elsif ($resp =~ /^n/i)  { $confirmed = 0; last; }
      else  {
        print "Please answer \"yes\" or \"no\".  ";
      }
    }# while confirm tags

  }# !$confirmed

  return ($episode_image,$episode_thumb);

}# get_episode_image()
