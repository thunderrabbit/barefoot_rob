#!/usr/bin/perl

use strict;
use Data::Dumper;
use DateTime;
use Date::Parse;

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
my $tz_date = $thedate . "T" . $thetime . $zoffset;
my $home = $ENV{HOME};    # https://stackoverflow.com/a/18123035

my $content_directory = "$home/barefoot_rob/content";
my $blog_directory = "/blog";    #  appended to $content_directory when writing actual file.
my $events_directory = "/events";    #  appended to $content_directory when writing actual file.
my $niigata_walk_dir = "/quests/walk-to-niigata";    #  appended to $content_directory when writing actual file.
my $slow_down_book_dir = "/quests/slow-down";    #  appended to $content_directory when writing actual file.

my %event_template_files = (
    "blog_entry" => "$home/barefoot_rob/templates/blog_template.txt",
    "book_chapter" => "$home/barefoot_rob/templates/book_chapter_template.txt",
    "weekly_alignment" => "$home/barefoot_rob/templates/event_weekly-alignment_template.txt",
    "walking_meditation" => "$home/barefoot_rob/templates/event_walking_meditation_template.txt",
    "quest_update" => "$home/barefoot_rob/templates/niigata_2021_walking_update.txt",
);

my %event_tag_hashes = (
    "blog_entry" => {"blog" => 1},
    "book_chapter" => {"book" => 1},
    "weekly_alignment" => {"weekly" => 1, "alignment" => 1, "event" => 1},
    "walking_meditation" => {"walk" => 1, "meditation" => 1, "event" => 1},
    "quest_update" => {"walk" => 1, "update" => 1, "quest" => 1},
);

my %event_title_prefixes = (
    "blog_entry" => "",
    "weekly_alignment" => "Weekly Alignment - ",
    "walking_meditation" => "Walking Meditation ",
    "book_chapter" => "",
    "quest_update" => "",
);

my $what_kinda_event = get_event_type(sort keys %event_template_files);

my $event_template_file = $event_template_files{$what_kinda_event};

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

my ($event_date, $event_date_human) = get_date($dt);

my $title = get_title($event_title_prefixes{$what_kinda_event});

my $tagstring = get_tags(%{$event_tag_hashes{$what_kinda_event}});  # returns qq/"mt3", "livestream", "maybe_others"/
my ($episode_image,$episode_thumb) = get_episode_image();

$new_entry->{title} = $title;
$new_entry->{tags} = $tagstring;
$new_entry->{EventDate} = $event_date;
# now build the output!
my $mt3_episode_output = $event_template;

# handle date separately
$mt3_episode_output =~ s/^(date: .*)/date: $tz_date/im;
$mt3_episode_output =~ s/human_date_here/$event_date_human/;
$mt3_episode_output =~ s/%episode_image/$episode_image/;
# do the rest algorithmically
foreach my $key (keys %$new_entry) {
  my $value = $new_entry->{$key};
  $mt3_episode_output =~ s/^(\Q$key\E: .*?)%s(.*)/$1$value$2/im;
}# $k


# store this for debugging
$new_entry->{mt3_episode_output} = $mt3_episode_output;

# Create outfile path based on today's date
# convention: the deepest directories are months, not days, so day is part of base filename, e.g. /yyyy/mm/ddtitle.md
my %event_output_directories = (
    "blog_entry" => $blog_directory . "/" . $dt->ymd("/"),             # don't end with slash, by `convention` above
    "book_chapter" => $slow_down_book_dir . "/" . $event_date . "_",   # don't end with slash because book directories have no dates
    "weekly_alignment" => $events_directory . "/" . $dt->ymd("/"),     # don't end with slash, by `convention` above
    "walking_meditation" => $events_directory . "/" . $dt->ymd("/"),   # don't end with slash, by `convention` above
    "quest_update" => $niigata_walk_dir . "/" . $dt->ymd("/"),         # don't end with slash, by `convention` above
);

my $alias_path = $event_output_directories{$what_kinda_event} . kebab_case($title);
my $outfile_path = $content_directory . $alias_path . ".md";   # $year/$month/$day were defined at top of script

$mt3_episode_output =~ s/alias_path/$alias_path/;

open(OUT, ">$outfile_path") or die "Could not open file '$outfile_path'";
print OUT $mt3_episode_output;
close(OUT);

print "+---------------------------------+\n";
print "| wrote to $outfile_path:                  |\n";
print "+---------------------------------+\n";


# DONE!
# END MAIN()
# SUBROUTINES FOLLOW
sub get_title($)
{
  my ($prefix) = (@_);
  my $confirmed = 0;
  my $title;
  while (!$confirmed) {
    print "Enter title that comes after '" . $prefix . "'\n\n";
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
        print "Please answer \"y\" or \"n\".  ";
      }
    }# while confirm tags
  }
  return $title;
}

sub get_date($) {
  my $confirmed = 0;
  my $user_dt;   # will be returned once we confirm its value
  my ($dt_now) = (@_);
  while (!$confirmed) {
    show_dates($dt_now);
    my $user_date = input_date($dt_now);
    $user_dt = parse_user_date($user_date);
    $confirmed = ask_confirm_date($user_dt);
  }
  # return two formats of date which has been parsed by `parse_user_date` and confirmed by user
  return ($user_dt->ymd, $user_dt->strftime("%A %d %B %Y"));
}

sub show_dates($) {
  my ($dt_now) = (@_);
  my $dt = $dt_now->clone;      # don't mess with global date
  my $desired_day_of_week = 4;  # Thursday
  print "in get date.   TODO: let us choose which upcoming Thursday to use.... \n";
  my $days_until_coming_thursday = ($desired_day_of_week + 7 - $dt->day_of_week) % 7;  #  https://codereview.stackexchange.com/a/33648/5794
  print $dt->day_of_week . "\n";
  print $days_until_coming_thursday . "\n";
  print "leavin get date\n";
  $dt->add( days => $days_until_coming_thursday );
  print $dt->day_name . " " . $dt->ymd . "\n";
  $dt->add( days => 7 );
  print $dt->day_name . " " . $dt->ymd . "\n";
  $dt->add( days => 7 );
  print $dt->day_name . " " . $dt->ymd . "\n";
  $dt->add( days => 7 );
  print $dt->day_name . " " . $dt->ymd . "\n";
  $dt->add( days => 7 );
  print $dt->day_name . " " . $dt->ymd . "\n";
}

sub ask_confirm_date($) {
  my ($dt) = (@_);
  my $string_to_confirm = $dt->strftime("%A %d %B %Y");   ##  Sunday 30 May 2021
  return confirm_string($string_to_confirm);
}

sub confirm_string($) {
  my ($string_to_confirm) = (@_);
  my $confirmed = 0;
  print "\nIs this correct?  (yes/no)\n";
  print "  $string_to_confirm\n";
  while (1) {
    my $resp = <STDIN>;
       $resp =~ s/^\s+|\s+$//g;

    if    ($resp =~ /^y/i) { $confirmed = 1; last; }
    elsif ($resp =~ /^n/i)  { $confirmed = 0; last; }
    else  {
      print "Please answer \"yes\" or \"no\".  ";
    }
  }
  return $confirmed;
}

sub input_date($) {
  my ($dt_now) = (@_);
  my $thedate = $dt->ymd;  # year-month-date (numeric).
  $thedate = "2021-06-20";    ###  hardcode while testing
  print "Input date of event: ($thedate)\n";
  my $user_date = <STDIN>;
  chomp($user_date);
  return length($user_date) ? $user_date : $thedate;
}

sub parse_user_date($) {
  my ($user_date) = (@_);
  print "in parse got this date: $user_date \n";
  my $epoch = str2time($user_date);    #  https://stackoverflow.com/a/7487117/194309
  return DateTime->from_epoch(epoch => $epoch, time_zone  => $zone);   # https://metacpan.org/pod/DateTime#DateTime-%3Efrom_epoch(-epoch-=%3E-$epoch,-...-)
}

sub kebab_case($) {
  my ($title) = (@_);
      $title = lc($title);    # make title lowercase
      $title =~ s/[\`\!\@\#\$\%\^\&\*\(\)\[\]\\\{\}\|\;\'\:\"\<\>\?\s]/-/g;
                              # replace special shell characters with hyphens (thanks to nooj)
      $title =~ s/-+/-/g;     # replace multiple hyphens with one (to match Hugo URLs)
  return $title;
}

sub get_tags($) {
  my $confirmed = 0;
  my $tagstring;
  my (%tags) = (@_);

  while (!$confirmed) {
    # put the tags in a hash

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

sub get_event_type() {
  my (@event_types) = (@_);
  my $event_type;
  my $selected_type;

    print "\n";
    print "Possible event types:\n";
    print "\n";

    my $num_event_types = scalar(@event_types);
    foreach my $ii (1..$num_event_types) {
      my $iipad = " " x (length($num_event_types) - length($ii));
      print "$iipad($ii) $event_types[$ii-1] $iipad($ii)\n";
    }# $ii

    $selected_type = "3";    ###  hardcode while testing
    print "Enter the number of the type you want to select: ($selected_type) ";
    my $raw_input = <STDIN>;

    $raw_input =~ s/\D+//g;     ## TODO: how to specify this ain't raw anymore?
    chomp($raw_input);
    $selected_type = length($raw_input) ? $raw_input : $selected_type;
    $event_type = $event_types[$selected_type-1];

    # confirm selected image
    print "\nCtrl-C if you ain't happy with your choice!\n";
    print "  event_type:     $event_type\n";

  return $event_type;
}

sub get_episode_image($) {
  my $confirmed = 0;
  my ($episode_image,$episode_thumb);

  while (!$confirmed) {

    print "\n";
    print "Please select the event image for the following event:\n";
    print "  title:     $title\n";
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
    }# while confirm images

  }# !$confirmed

  return ($episode_image,$episode_thumb);

}# get_episode_image()
