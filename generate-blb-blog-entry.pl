#!/usr/bin/perl

use strict;
use Data::Dumper;

my $verbosity = 1; # integer from 0 (silent) to 5 (all the debugging info).

# oh god dates are so annoying
my $thedate = `date +%Y-%m-%d`;  chomp $thedate;  # year-month-date (numeric).
my $thetime = `date +%H-%M-%S`;  chomp $thetime;  # hour-min-sec    (numeric).
my $year    = `date +%Y`;        chomp $year;
my $month   = `date +%m`;        chomp $month;
my $day     = `date +%d`;        chomp $day;

my $zone = "Japan/Tokyo";
my $zoffset = "+09:00";

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



exit;
# Get input data from commands
# TODO: error handling
#
my $mt3_episode_template;
my $bframes_output;
my $known_videos_diff;

my $run_live = 0;
if ($run_live) {
  local $/;  # makes changes local to this block
  undef $/;  # file slurp mode (default is "\n")

  open (MET,"<mt3_episode_template.txt");
  $mt3_episode_template = <MET>;
  close MET;

  $bframes_output = `cd ~/mt3; ./bframes.sh`;
  $known_videos_diff = `cd ~/mt3.com; ./deploy.sh; git diff data/playlists/knownvideos.toml`;

} else {
  # debug interface just to get the bulk of the code working

  local $/;  # makes changes local to this block
  undef $/;  # file slurp mode (default is "\n")
  open (MET,"<mt3_episode_template.txt");
  open (BO, "<bframes_output.txt");
  open (KVD,"<known_videos_diff.txt");

  $mt3_episode_template = <MET>;
  $bframes_output = <BO>;
  $known_videos_diff = <KVD>;

  close MET;
  close BO;
  close KVD;
}# $run_live

if ($verbosity > 2) {
  print "length(MET) = " . length($mt3_episode_template) . "\n";
  print "length(BO)  = " . length($bframes_output) . "\n";
  print "length(KVD) = " . length($known_videos_diff) . "\n";
}



## PROCESS KNOWN_VIDEOS_DIFF
#
# The string "+  [Videos." reliably separates new videos.
# Split $known_videos_diff on that string
my @blobs = split /^\+\s+\[Videos\./m, $known_videos_diff;
shift @blobs;  # first blob is the crap before the first new video

foreach my $blob (@blobs) {
  # Each blob starts with the video information,
  # and has garbage afterward.
  # Grab the good information, not the garbage!
  print "blob = $blob\n"  if $verbosity > 4;

  # If the format can vary, these regexes will get more complicated
  my ($id)    = $blob =~ /^\+ \s+ VideoId = "(.+)"/mi;
  my ($title) = $blob =~ /^\+ \s+ Title = "(.+)"/mi;
  my ($pubd)  = $blob =~ /^\+ \s+ Published = (.+)/mi;
  my ($dur)   = $blob =~ /^\+ \s+ Duration = (.+)/mi;


  if ($verbosity > 2) {
    print "id    = $id   \n";
    print "title = $title\n";
    print "pubd  = $pubd \n";
    print "dur   = $dur  \n";
  }

  $pubd  =~ s/Z$//;        # remove trailing Z from youtube date format
  $title =~ s/.*?://;      # delete stuff up to and including the first :
  $title =~ s/(^ | $)//g;  # delete leading and trailing space

  # Have we already seen a video with this title?
  # If so, we will keep only the longest one.
  # If not, this one is by definition the longest!
  if (exists($new_videos->{$title})) {

    # Is this video's duration shorter than the one we've seen?
    if ($dur < $new_videos->{$title}->{duration}) {
      # If so, skip this video.
      next;
    }# $dur
  }# exists

  # if we are here, this is the video we want to keep.
  # overwrite the previous video (if any).
  $new_videos->{$title} = {
    youtube => $id,
    title => $title,
    published => "$pubd$zoffset",
    duration => $dur
  };
}# $blob


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
foreach my $title (keys %$new_videos) {
  my $nv = $new_videos->{$title};

  my $tagstring = get_tags($nv);  # returns qq/"mt3", "livestream", "maybe_others"/
  my ($episode_image,$episode_thumb) = get_episode_image($nv);

  $new_videos->{$title}->{tags} = $tagstring;
  $new_videos->{$title}->{episode_image} = $episode_image;
  $new_videos->{$title}->{episode_thumbnail} = $episode_thumb;

  # now build the output!
  my $mt3_episode_output = $mt3_episode_template;

  # handle date separately
  $mt3_episode_output =~ s/^(date: .*)/date: $nv->{published}/im;

  # do the rest algorithmically
  foreach my $key (keys %$nv) {
    my $value = $nv->{$key};
    $mt3_episode_output =~ s/^(\Q$key\E: .*?)%s(.*)/$1$value$2/im;
  }# $k


  # append images
  $mt3_episode_output .= "Here are the frames taken today:\n\n";  # should this go in the template?
  $mt3_episode_output .= $frameout;

  # store this for debugging
  $new_videos->{$title}->{mt3_episode_output} = $mt3_episode_output;

  # TODO: Write the final output to a file.
  print "+---------------------------------+\n";
  print "| file.md output:                 |\n";
  print "+---------------------------------+\n";
  print $mt3_episode_output;

}# $title

print "new_videos = \n" . Dumper($new_videos)  if $verbosity > 2;


# DONE!
# END MAIN()
# SUBROUTINES FOLLOW


sub get_tags($) {
  my ($nv) = (@_);

  my $confirmed = 0;
  my $tagstring;


  while (!$confirmed) {
    # put the tags in a hash
    my %tags = ("mt3" => 1, "livestream" => 1);

    print "\n";
    print "Please enter tags for the following video,\n";
    print "separated by commas or carriage returns.\n";
    print "  title:     $nv->{title}\n";
    print "  youtubeID: $nv->{youtube}\n";
    print "  published: $nv->{published}\n";
    print "  duration:  $nv->{duration}\n";
    print "\n";
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

      if    ($resp =~ /^yes$/i) { $confirmed = 1; last; }
      elsif ($resp =~ /^no$/i)  { $confirmed = 0; last; }
      else  {
        print "Please answer \"yes\" or \"no\".  ";
      }
    }# while confirm tags

  }# !$confirmed

  return $tagstring;
}# get_tags()



sub get_episode_image($) {
  my ($nv) = (@_);
  my $confirmed = 0;
  my ($episode_image,$episode_thumb);

  while (!$confirmed) {

    print "\n";
    print "Please select the episode image for the following video:\n";
    print "  title:     $nv->{title}\n";
    print "  youtubeID: $nv->{youtube}\n";
    print "  published: $nv->{published}\n";
    print "  duration:  $nv->{duration}\n";
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

      if    ($resp =~ /^yes$/i) { $confirmed = 1; last; }
      elsif ($resp =~ /^no$/i)  { $confirmed = 0; last; }
      else  {
        print "Please answer \"yes\" or \"no\".  ";
      }
    }# while confirm tags

  }# !$confirmed

  return ($episode_image,$episode_thumb);

}# get_episode_image()
