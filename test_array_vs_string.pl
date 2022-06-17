#!/usr/bin/perl

use strict;

# https://stackoverflow.com/a/46550384/194309
use Cwd qw( abs_path );
use File::Basename qw( dirname );
use lib dirname(abs_path(__FILE__));
use rpl::Constants;
use rpl::Functions;

my $verbosity = 10; # integer from 0 (silent) to 5 (all the debugging info).

my $event_templates_selector;
my @event_templates_array;
my %select_from_hash = %rpl::Constants::event_template_files;
my $what_kinda_event;

##  This do loop allows %event_template_files to contain a reference to another hash so we can get more detailed templates
##  At this point we can go down to the location level, but cannot poop out multiple templates per event (e.g. multi-language / different platforms (my site / FB / Meetup / Instagram))


# TODO: return an array of templates and we'll loop through each one when outputting stuff

my $original_what_kinda_event = "";     ## later restore what_kinda_event after we go into sub-hashes for walking events so we can get tags and location later down this script

do {

  $what_kinda_event = rpl::Functions::choose_from_list_of("Event Types", sort keys %select_from_hash);  # First parameter is for human to know what types of things are in the list

  $original_what_kinda_event = $what_kinda_event unless $original_what_kinda_event;

  $event_templates_selector = $select_from_hash{$what_kinda_event};

  ## so instead I am checking the string and choosing the appropriate hash here.  As of 29 Sep 2021, "walk_location_files" is the only option
  if($event_templates_selector eq "walk_location_files") {
    print "\n$event_templates_selector? We must go deeper!\n";
    %select_from_hash = %rpl::Constants::walk_location_files;
  } elsif($event_templates_selector eq "the_good_place") {
    print "\n$event_templates_selector? We must go deeper!\n";
    %select_from_hash = %rpl::Constants::the_good_place;
  }

} until (rpl::Functions::is_array($event_templates_selector));

## restore $what_kinda_event which may have gotten borked when diving into sub hashes
$what_kinda_event = $original_what_kinda_event;

@event_templates_array = @$event_templates_selector;

print @event_templates_array;
