#!/usr/bin/perl

use strict;

# https://stackoverflow.com/a/46550384/194309
use Cwd qw( abs_path );
use File::Basename qw( dirname basename );
use File::Path qw( make_path );     # For recursive mkdir to any depth
use lib dirname(abs_path(__FILE__));
use rpl::Constants;
use rpl::BLTConstants;    # for Bold Life Tribe automated titles and content
use rpl::Functions;

my $verbosity = 10; # integer from 0 (silent) to 5 (all the debugging info).

my $event_type_selector;
my @event_paths_array;
my %select_from_hash = %rpl::Constants::event_template_files;
my $what_kinda_event;

rpl::Functions::logthis("STARTING_ANEW\n");
##  This do loop allows %event_template_files to contain a reference to another hash so we can get more detailed templates
##  At this point we can go down to the location level, and poop out multiple templates per event (e.g. multi-language / different platforms (my site / FB / Meetup / Instagram))

my $original_what_kinda_event = "";     ## later restore what_kinda_event after we go into sub-hashes for walking events so we can get tags and location later down this script

do {

  $what_kinda_event = rpl::Functions::get_event_type("Event Types", sort keys %select_from_hash);

  $event_type_selector = $select_from_hash{$what_kinda_event};

  ## so instead I am checking the string and choosing the appropriate hash here.  As of 29 Sep 2021, "walk_location_files" is the only option
  if($event_type_selector eq "walk_location_files") {
    print "\n$event_type_selector? We must go deeper!\n";
    %select_from_hash = %rpl::Constants::walk_location_files;
  } elsif($event_type_selector eq "the_good_place") {
    print "\n$event_type_selector? We must go deeper!\n";
    %select_from_hash = %rpl::Constants::the_good_place;
  }

} until (rpl::Functions::is_array($event_type_selector));

@event_paths_array = @$event_type_selector;

my $title_image = "";   ## Getting this via $ARGV[0]..  not sure how else makes sense to get it

# Get input data from commands
# TODO: error handling
#
my %event_templates;   ## 'bout to get multiple templates (one per language, social network)

## Load each template in the selected array
foreach(@event_paths_array) {
  my $extension;   ## only needed up here because of the { #debug interface } block
  {
    # debug interface just to get the bulk of the code working

    local $/;  # makes changes local to this block
    undef $/;  # file slurp mode (default is "\n")

    $_ =~ /[^\.]+(.*)/;    ## Grab extension, from first period onward
    $extension = $1;

    if ($verbosity > 3) {
      print "template extension `" . $extension . "` should be used when writing file based on this template\n";
    }

    if ($verbosity > 2) {
      print "loading template:\n" . $_ . "\n";
    }
    open (ETF, "<", $_) or die "could not find template " . $_;

    $event_templates{$extension} = <ETF>;

    close ETF;
  }

  if ($verbosity > 2) {
    print "length(ETF) = " . length($event_templates{$extension}) . "\n";
  }
}

my $number_args = $#ARGV + 1;
my $need_image_url = 0;   # if image URLs were sent on command line, we can just select from them
if ($number_args == 0) {
    print "Feel free to send images as arguments.\n";
    $need_image_url = 1;  # images URLs were not sent on command line.  This allows embedding image URL in event_generators/
}

# Do the same for episodes as we did for frames.
# Because we don't have to monkey with the $id here,
# we can do the whole thumbs loop in one line.
my @episode_images = @ARGV;
my @episode_thumbs = map { m{(.*)/([^/]+)}; "$1/thumbs/$2" } @episode_images;

my $preferred_day_of_week = $rpl::Constants::event_day_of_week{$what_kinda_event};
my $event_date_time = rpl::Functions::get_date($rpl::Functions::dt,$preferred_day_of_week);   # default is now
my $guessed_gathering_time = $event_date_time->clone->subtract( minutes => 15 );      # clone = don't mess with other date
my $t_minus_14_days_date = $event_date_time->clone->subtract( days => 14 );      # clone = don't mess with other date
my $t_minus_07_days_date = $event_date_time->clone->subtract( days => 7 );      # clone = don't mess with other date
my $first_gathering_time = rpl::Functions::get_time("gathering time of event",$guessed_gathering_time);
my $first_departure_time = $first_gathering_time->clone->add( minutes => 15 )->strftime("%H:%M");      # Only used for Shin Yuri Art Park, with two meeting points
print "event date time: $event_date_time" . "\n";
print "first gathering time: $first_gathering_time" . "\n";
print "first departure time: $first_departure_time" . "\n";

my $title;

### will need to get a title for each language, but not for each social network.. hmmm
### Also, I want to use the same filename (in English) even for the Japanese output
if($what_kinda_event eq "bold_life_tribe") {
  my $blt_month = $event_date_time->month;  # https://metacpan.org/pod/DateTime#$dt-%3Emonth
  my $blt_week = $event_date_time->weekday_of_month;  # https://metacpan.org/pod/DateTime#$dt-%3Eweekday_of_month

  my $prefix = $rpl::Constants::event_title_prefixes{$what_kinda_event};
  my $theme = $rpl::BLTConstants::bold_life_tribe_themes{$blt_month};  # 2 should return TRUTH
  my $topic = $rpl::BLTConstants::bold_life_tribe_weekly_titles{$theme}[$blt_week - 1];  # TRUTH 1 should return "the feather and the sword"

  $title = rpl::Functions::get_title($prefix . " - " . $theme . " " . $blt_week . " - " . $topic);
} else {
  $title = rpl::Functions::get_title($rpl::Constants::event_title_prefixes{$what_kinda_event});
}

my $tagstring = rpl::Functions::get_tags(%{$rpl::Constants::event_tag_hashes{$what_kinda_event}});  # returns qq/"mt3", "livestream", "maybe_others"/
my ($episode_image,$episode_thumb);
if($need_image_url) {
  ($episode_image,$episode_thumb) = rpl::Functions::get_image_url($title);
} else {
  ($episode_image,$episode_thumb) = rpl::Functions::get_episode_image($title, @episode_images, @episode_thumbs);
}

# Create alt-text for (title) image
my $episode_image_alt = basename($episode_image);
$episode_image_alt =~ s/_+/ /g;     ## remove underscores
$episode_image_alt =~ s/\..*//g;    ## remove image file extension
## BUILD OUTPUT
#
my $new_entry;

$new_entry->{title} = $title;
$new_entry->{tags} = $tagstring;
$new_entry->{EventDate} = $event_date_time->ymd;

# now build the outputs!
foreach my $extension (keys %event_templates) {
  my $mt3_episode_output = $event_templates{$extension};

  # handle date separately
  $mt3_episode_output =~ s/^(date: .*)/date: $rpl::Functions::tz_date/im;  ## timestamp of when ./generate_events.pl was called
  my $human_date = $event_date_time->strftime("%A %d %B %Y");  # https://metacpan.org/pod/DateTime#strftime-Patterns
  my $date_14_days_before = $t_minus_14_days_date->strftime("%A %d %B %Y");
  my $date_07_days_before = $t_minus_07_days_date->strftime("%A %d %B %Y");
  my $event_yyyy = $event_date_time->year;   # https://metacpan.org/pod/DateTime
  my $event_m = $event_date_time->month;     # 1 .. 12
  my $event_d = $event_date_time->day;       # 1 .. 31
  my $event_h = $event_date_time->hour;      # e.g. 15
  my $event_h12ap = $event_date_time->hour_12 . $event_date_time->am_or_pm;    # e.g. 3pm
  my $event_minute = $event_date_time->minute;
  my $event_day_month_date = rpl::Functions::ordinate($event_date_time->strftime("%A, %B %d"));  # 24 hour format
  my $event_time = $event_date_time->strftime("%H:%M");  # 24 hour format
  my $first_gathering_TIME = $first_gathering_time->strftime("%H:%M");
  $mt3_episode_output =~ s/EVENT_TITLE/$title/g;
  $mt3_episode_output =~ s/HUMANDATE/$human_date/g;
  $mt3_episode_output =~ s/EVENT_DAY_MONTH_DATE/$event_day_month_date/g;   # for reminders
  $mt3_episode_output =~ s/T_MINUS_14_DAYS_DATE/$date_14_days_before/g;    # for reminders
  $mt3_episode_output =~ s/T_MINUS_07_DAYS_DATE/$date_07_days_before/g;    # for reminders
  $mt3_episode_output =~ s/EVENT_YYYY/$event_yyyy/g;
  $mt3_episode_output =~ s/EVENT_M/$event_m/g;
  $mt3_episode_output =~ s/EVENT_D/$event_d/g;
  $mt3_episode_output =~ s/EVENT_H/$event_h/g;
  $mt3_episode_output =~ s/EVENT_H12ap/$event_h12ap/g;
  $mt3_episode_output =~ s/EVENT_TIME/$event_time/g;
  $mt3_episode_output =~ s/FIRST_GATHERING_TIME/$first_gathering_TIME/g;
  $mt3_episode_output =~ s/FIRST_DEPARTURE_TIME/$first_departure_time/g;
  $mt3_episode_output =~ s/episode_image/$episode_image/;
  $mt3_episode_output =~ s/episode_image_alt/$episode_image_alt/;
  # do the rest algorithmically
  foreach my $key (keys %{ $new_entry }) {
    my $value = $new_entry->{$key};
    $mt3_episode_output =~ s/^(\Q$key\E: .*?)%s(.*)/$1$value$2/im;
  }# $k


  # store this for debugging
  $new_entry->{mt3_episode_output} = $mt3_episode_output;

  # Create outfile path based on today's date
  # convention: the deepest directories are months, not days, so day is part of base filename, e.g. /yyyy/mm/ddtitle.md
  #  Will default to events.
  my %event_output_directories = (
      "blog_entry" => $rpl::Constants::blog_directory . "/" . $rpl::Functions::dt->ymd("/"),             # don't end with slash, by `convention` above
      "book_chapter" => $rpl::Constants::slow_down_book_dir . "/" . rpl::Functions::prepend_book_title_based_on_date($event_date_time) . "-",   # don't end with slash because book directories have no dates
      "mkp_family" =>  "/",     # eventually create in MKP Japan web directory?
      "quest_update" => $rpl::Constants::niigata_walk_dir . "/" . $rpl::Functions::dt->ymd("/"),         # don't end with slash, by `convention` above
  );

  my $alias_path = $event_output_directories{$what_kinda_event};
  ##  don't require every walk_and_talk location in %event_output_directories
  $alias_path = $rpl::Constants::events_directory . "/" . $event_date_time->ymd("/") unless $alias_path;
  my $title_path = rpl::Functions::kebab_case($title);
  my $outfile_path = $rpl::Constants::content_directory . $alias_path;   # oh, this includes the dd part of the filename (ddtitle.md)
  my $outfile_and_title_path = $outfile_path . $title_path . $extension;

  my $dirname_of_output_file = dirname($outfile_and_title_path);

  ## https://stackoverflow.com/a/701494/194309
  eval { make_path($dirname_of_output_file) };        # Recursive mkdir to any depth
  if ($@) {
    print "Couldn't create $dirname_of_output_file: $@";
  }

  $mt3_episode_output =~ s|alias_path|$alias_path$title_path|g;

  open(OUT, ">", $outfile_and_title_path) or die "Could not open file '$outfile_and_title_path'";
  print OUT $mt3_episode_output;
  close(OUT);

  print "+---------------------------------+\n";
  print "| wrote to $outfile_and_title_path\n";
  print "+---------------------------------+\n";
}

rpl::Functions::logthis("\nFINISHED_ADIEU\n");
# DONE!
