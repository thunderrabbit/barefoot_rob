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
use Number::Spell;    # to help create titles for realtime_book_chapter

my $verbosity = 10; # integer from 0 (silent) to 5 (all the debugging info).

my $event_type_selector;
my @event_paths_array;
my %select_from_hash = %rpl::Constants::event_template_files;
my $what_kinda_event;

rpl::Functions::logthis("STARTING_ANEW\n");
##  This do loop allows %event_template_files to contain a reference to another hash so we can get more detailed templates
##  At this point we can go down to the location level, and poop out multiple templates per event (e.g. multi-language / different platforms (my site / FB / Meetup / Instagram))

my $original_what_kinda_event;     ## later restore what_kinda_event after we go into sub-hashes for walking events so we can get tags and location later down this script

do {

  $what_kinda_event = rpl::Functions::choose_from_list_of("Event Types", sort keys %select_from_hash);  # First parameter is for human to know what types of things are in the list
  $original_what_kinda_event //= $what_kinda_event;   # defined-or operator via chatGPT

  $event_type_selector = $select_from_hash{$what_kinda_event};

  print("Just now selected $what_kinda_event which is $event_type_selector\n");
  ## so instead I am checking the string and choosing the appropriate hash here.  As of 29 Sep 2021, "walk_location_files" is the only option
  if($event_type_selector eq "walk_location_files") {
    print "\n$event_type_selector? We must walk deeper!\n";
    %select_from_hash = %rpl::Constants::walk_location_files;
  } elsif($event_type_selector eq "cuddle_party_files") {
    print "\n$event_type_selector? Cuddle where?\n";
    %select_from_hash = %rpl::Constants::cuddle_party_files;
  } elsif($event_type_selector eq "book_chapter_files") {
    print "\n$event_type_selector? Write what?\n";
    %select_from_hash = %rpl::Constants::book_chapter_files;
  } elsif($event_type_selector eq "previous_generators") {
    print "\n$event_type_selector? Which do you wanna copy?\n";
    # Get a hash of keys and file paths of generators created in the past month:
    %select_from_hash = rpl::Functions::get_hash_of_recent_generators($rpl::Functions::dt->clone->subtract( days => 30 ), $rpl::Functions::dt);
  }

  # if we get an array, assume we have an array of templates
  # if we get a single file path, assume we are copying a previous generator to a new one
  # if we get a hash, use the hash to keep drilling down within this loop.
} until (rpl::Functions::is_array($event_type_selector)  || rpl::Functions::this_looks_like_a_file_path($event_type_selector));

my %event_templates;
my $thing_to_do = "unknown";
if(rpl::Functions::is_array($event_type_selector)) {
  # We have a list of templates, so load their contents which will be filled with data we enter next
  %event_templates = rpl::Functions::return_contents_of_array_of_files(@$event_type_selector);   ## 'bout to get multiple templates (one per language, social network)
  $thing_to_do = "create event";
}
if(rpl::Functions::this_looks_like_a_file_path($event_type_selector)) {
  # We have a single event generator.  We want to make a new one based on date, title, and optional image
  print "We need to copy the file at path\n$event_type_selector\n";
  print "to a file that matches the date we get down below, then change the dates in the file.\n";
  print "However, probably never going to finish this because I might not do that many more new barefoot events\n";
  print "after Misa helped me recognize that I should focus on fewer, cooler events.\n";
  print "  - Rob\n  1 July 2022\n\n";
  $thing_to_do = "copy generator";
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
my $preferred_event_time = $rpl::Constants::event_primary_time{$what_kinda_event};
my $get_time_bool = ($thing_to_do ne "copy generator");  # only need time if not creating a generator
my $event_date_time = rpl::Functions::parse_user_date("2023-05-06 10:48:53");  # Without ->ymd "T11:45:00" appends to the date
print("This is when I skipped event time for Book chapters ".$event_date_time->strftime("%A %d %B %Y %H:%M:%S"));
if($what_kinda_event ne "otter_book_chapter") {
  $event_date_time = rpl::Functions::get_date($rpl::Functions::dt,$preferred_day_of_week,$preferred_event_time, $get_time_bool);   # default is now
}
my $preferred_gathering_duration = $rpl::Constants::gather_minutes_before_event{$what_kinda_event} || 15;
#-- begin figure out cleanup time
print("This is when I fixed the event end time for Cuddle Party events: 2023-03-18 16:22");
my $event_will_finish_dt = rpl::Functions::parse_user_date("2023-03-18 16:22");  # Without ->ymd "T11:45:00" appends to the date
if($original_what_kinda_event eq "cuddle_party") {
  my $room_finished_time = rpl::Functions::get_time("when we must leave room by",$event_date_time->clone->add( hours => 5 ));
  my $preferred_cleanup_duration = 15;
  $event_will_finish_dt = $room_finished_time->clone->subtract( minutes => $preferred_cleanup_duration );
}
#-- end figure out cleanup time

my $guessed_gathering_time;
print("if this fails, know the value of what_kinda_event is " . $what_kinda_event . "\n");
unless($what_kinda_event eq "realtime_book_chapter" || rpl::Functions::this_looks_like_a_file_path($event_type_selector)) {
   $guessed_gathering_time = $event_date_time->clone->subtract( minutes => $preferred_gathering_duration );      # clone = don't mess with other date
}
my $t_minus_14_days_date = $event_date_time->clone->subtract( days => 14 );      # clone = don't mess with other date
my $t_minus_07_days_date = $event_date_time->clone->subtract( days => 7 );      # clone = don't mess with other date
my $bold_life_tribe_publish_date = $event_date_time->clone->subtract( days => 8 );  # 6 if we can get Hugo to stop lagging by being on DH server in California time zone     # Publish Bold Life Tribe just N days ahead so they don't swamp future even though I can bang them out
my $first_gathering_time;

#  $walk_trip_started only used for realtime_book_chapter to help calculate Titles
print("This date is only related to walks; you can ignore it: 2021-04-16 12:00");
my $walk_trip_started = rpl::Functions::parse_user_date("2021-04-16 12:00");  # Without ->ymd "T11:45:00" appends to the date
my $ordinal_day_number;   # Used for realtime_book_chapter title and tags

if($original_what_kinda_event eq "book_chapter" || rpl::Functions::this_looks_like_a_file_path($event_type_selector)) {
  # Don't need gathering_time, but do need a timestamp because of $first_gathering_time code etc
  $first_gathering_time = $event_date_time;   # not used for realtime_book_chapter
} else {
  $first_gathering_time = rpl::Functions::get_time("gathering time of event",$guessed_gathering_time);
}
my $first_departure_time = $first_gathering_time->clone->add( minutes => 15 )->strftime("%H:%M");      # Only used for Shin Yuri Art Park, with two meeting points
my $izumi_departure_time = $first_gathering_time->clone->add( minutes => 10 )->strftime("%H:%M");      # Only used for Izumi Tamagawa (five minutes walk to BLUE)
my $arrive_by_time = $event_date_time->clone->subtract( minutes => 10 )->strftime("%H:%M");
print "event date time: $event_date_time\n";
print "first gathering time: $first_gathering_time\n";
print "first departure time: $first_departure_time\n";

my $title;
my $topic;   # e.g. February is the month of __TRUTH__
my $blurb;   # paragraph to fill in BLURB_BLOCK
my $chapter_contents;   # for creating realtime_book_chapters

### will need to get a title for each language, but not for each social network.. hmmm
### Also, I want to use the same filename (in English) even for the Japanese output
if($what_kinda_event eq "bold_life_tribe") {
  my $blt_month = $event_date_time->month;  # https://metacpan.org/pod/DateTime#$dt-%3Emonth
  my $blt_week = $event_date_time->weekday_of_month;  # https://metacpan.org/pod/DateTime#$dt-%3Eweekday_of_month

  my $prefix = $rpl::Constants::event_title_prefixes{$what_kinda_event};   # "Bold Life Tribe"
  my $theme = $rpl::BLTConstants::bold_life_tribe_themes{$blt_month};  # e.g. TRUTH
  my $tagline = $rpl::BLTConstants::bold_life_tribe_weekly_titles{$theme}[$blt_week - 1];  # e.g. "the feather and the sword"

  $title = rpl::Functions::get_title($prefix . " - " . $theme . " " . $blt_week . " - " . $tagline);
  $topic = $event_date_time->month_name . " is the month of __".$theme."__";  # https://metacpan.org/pod/DateTime#$dt-%3Emonth_name
  $blurb = rpl::Functions::blt_blurb_for_date($event_date_time);
  unless ($blurb) {
    print "Need to create blurb file\n";
    rpl::Functions::blt_create_empty_blurb_file_for_date($event_date_time);
  }
} elsif($what_kinda_event eq "realtime_book_chapter") {
  print("walk trip started on $walk_trip_started\n");
  print("event date time on $event_date_time\n");
  $ordinal_day_number = $event_date_time->subtract_datetime($walk_trip_started)->in_units('days')+1;
  print("So this entry is for Day $ordinal_day_number\n");
  my $prefix = "Day $ordinal_day_number - "; # "Day 18 - "
  print("Spelled as $prefix\n");
  $title = rpl::Functions::get_title("");   # send $prefix if you want "Day nn - " as title prefix
  $chapter_contents = rpl::Functions::book_content_for_date($event_date_time);
} elsif(rpl::Functions::this_looks_like_a_file_path($event_type_selector)) {
  print("No need to get title because we are copying event\n");
} else {
  $title = rpl::Functions::get_title($rpl::Constants::event_title_prefixes{$what_kinda_event});
}

print("If this fails, add Constants::event_tag_hashes{$what_kinda_event}\n");
my %taghash = %{$rpl::Constants::event_tag_hashes{$what_kinda_event}};
if($what_kinda_event eq "realtime_book_chapter") {
  #  $taghash{"day-$ordinal_day_number"} = 1;              # Add Day Number to tags
}
$taghash{$event_date_time->year} = 1;              # Add year to tags
$taghash{lc($event_date_time->month_name)} = 1;    # Add lowercase month to tags
my $tagstring = rpl::Functions::get_tags(%taghash);  # returns qq/"mt3", "livestream", "maybe_others"/
my ($episode_image,$episode_thumb,$image_credit);
if($need_image_url) {
  ($episode_image,$episode_thumb) = rpl::Functions::get_image_url($title);
  $image_credit = rpl::Functions::get_image_credit();
} else {
  ($episode_image,$episode_thumb) = rpl::Functions::get_episode_image($title, @episode_images, @episode_thumbs);
}

my ($peatix_prefix, $suggested_ticket_link);
if($original_what_kinda_event eq "cuddle_party") {
  # get ticket link
  my $template = "cuddle-party-tokyo-%s-%d";
  $peatix_prefix = sprintf($template, lc($event_date_time->month_name), $event_date_time->year);
  $suggested_ticket_link = "https://" . $peatix_prefix . ".peatix.com/";

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
  if($what_kinda_event eq "bold_life_tribe") {
    $mt3_episode_output =~ s/^(date: .*)/date: $bold_life_tribe_publish_date$rpl::Functions::zoffset/im;  ## timestamp of when ./generate_events.pl was called
  } else {
    $mt3_episode_output =~ s/^(date: .*)/date: $rpl::Functions::tz_date/im;  ## timestamp of when ./generate_events.pl was called
  }
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
  my $event_time_plus_ten = $event_date_time->clone->add( minutes => 10 )->strftime("%H:%M");      # Only used for Manpukuji Hiyama (ten minutes walk from 新百合ヶ丘駅)
  my $event_time_plus_180 = $event_date_time->clone->add( minutes => 180 )->strftime("%H:%M");      # Used for Cuddle Party end time
  my $event_finished_by_time = $event_will_finish_dt->strftime("%H:%M");
  my $first_gathering_TIME = $first_gathering_time->strftime("%H:%M");
  my $event_location = $rpl::Constants::event_locations{$what_kinda_event};
  $mt3_episode_output =~ s/TOPIC_LINE/$topic/;
  $mt3_episode_output =~ s/BLURB_BLOCK/$blurb/;
  $mt3_episode_output =~ s/CHAPTER_BLOCK/$chapter_contents/;
  $mt3_episode_output =~ s/EVENT_TITLE/$title/g;
  $mt3_episode_output =~ s/EVENT_LOCATION/$event_location/g;
  $mt3_episode_output =~ s/HUMANDATE/$human_date/g;
  $mt3_episode_output =~ s/EVENT_DAY_MONTH_DATE/$event_day_month_date/g;   # for reminders
  $mt3_episode_output =~ s/T_MINUS_14_DAYS_DATE/$date_14_days_before/g;    # for reminders
  $mt3_episode_output =~ s/T_MINUS_07_DAYS_DATE/$date_07_days_before/g;    # for reminders
  $mt3_episode_output =~ s/EVENT_YYYY/$event_yyyy/g;
  $mt3_episode_output =~ s/EVENT_M/$event_m/g;
  $mt3_episode_output =~ s/EVENT_D/$event_d/g;
  $mt3_episode_output =~ s/EVENT_H/$event_h/g;
  $mt3_episode_output =~ s/EVENT_H12ap/$event_h12ap/g;
  $mt3_episode_output =~ s/EVENT_TIME_PLUS_10/$event_time_plus_ten/g;
  $mt3_episode_output =~ s/THREE_HOURS_AFTER_EVENT_TIME/$event_time_plus_180/g;
  $mt3_episode_output =~ s/ARRIVE_BY_TIME/$arrive_by_time/g;
  $mt3_episode_output =~ s/EVENT_TIME/$event_time/g;
  $mt3_episode_output =~ s/15_B4_RENTAL_ENDS/$event_finished_by_time/g;
  $mt3_episode_output =~ s/FIRST_GATHERING_TIME/$first_gathering_TIME/g;
  $mt3_episode_output =~ s/FIRST_DEPARTURE_TIME/$first_departure_time/g;
  $mt3_episode_output =~ s/IZUMI_DEPARTURE_TIME/$izumi_departure_time/g;
  $mt3_episode_output =~ s/episode_image/$episode_image/;
  $mt3_episode_output =~ s/episode_image_alt/$episode_image_alt/;
  $mt3_episode_output =~ s/IMAGE_CREDIT/$image_credit/g;
  $mt3_episode_output =~ s/TICKET_LINK_PREFIX/$peatix_prefix/g;
  $mt3_episode_output =~ s/TICKET_LINK/$suggested_ticket_link/g;
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
      "realtime_book_chapter" => $rpl::Constants::slow_down_book_dir . "/" . rpl::Functions::prepend_book_title_based_on_date($event_date_time) . "-",   # don't end with slash because book directories have no dates
      "otter_book_chapter" => $rpl::Constants::slow_down_book_dir . "/",
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
