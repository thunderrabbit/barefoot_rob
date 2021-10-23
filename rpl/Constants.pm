package rpl::Constants;

use strict;
use DateTime;

our $home = $ENV{HOME};    # https://stackoverflow.com/a/1451420/194309

my $dt = DateTime->now();

our $event_generator_log = "$home/barefoot_rob_master/event_generators/" . $dt->ymd("_") . "_log.txt";
our $content_directory = "$home/barefoot_rob_master/content";
our $blog_directory = "/blog";    #  appended to $content_directory when writing actual file.
our $events_directory = "/events";    #  appended to $content_directory when writing actual file.
our $niigata_walk_dir = "/quests/walk-to-niigata";    #  appended to $content_directory when writing actual file.
our $slow_down_book_dir = "/quests/slow-down";    #  appended to $content_directory when writing actual file.

our %walk_location_files = (
    "yoyogi_park" => [
      "$home/barefoot_rob_master/event_templates/walk_and_talk/yoyogi_park/yoyogi_park.en.md",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/yoyogi_park/yoyogi_park.ja.md",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/yoyogi_park/yoyogi_park.facebook.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/yoyogi_park/yoyogi_park.meetup.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/yoyogi_park/yoyogi_park.twitter.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/___.t-07days_reminder.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "izumi_tamagawa" => [
      "$home/barefoot_rob_master/event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.en.md",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.ja.md",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.facebook.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.meetup.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.message.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.twitter.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/___.t-07days_reminder.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "izumi_tamagawa_full_moon" => [
      "$home/barefoot_rob_master/event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.en.md",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.ja.md",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.facebook.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.meetup.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.message.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.twitter.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/___.t-07days_reminder.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "shin_yuri_art_park" => [
      "$home/barefoot_rob_master/event_templates/walk_and_talk/shin_yuri_art_park/shin_yuri_art_park.en.md",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/shin_yuri_art_park/shin_yuri_art_park.ja.md",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/shin_yuri_art_park/shin_yuri_art_park.facebook.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/shin_yuri_art_park/shin_yuri_art_park.meetup.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/shin_yuri_art_park/shin_yuri_art_park.twitter.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/___.t-07days_reminder.txt",
      "$home/barefoot_rob_master/event_templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
);

our %event_template_files = (
    "blog_entry" => [
      "$home/barefoot_rob_master/event_templates/blog_template.md",
    ],
    "book_chapter" => [
      "$home/barefoot_rob_master/event_templates/book_chapter_template.md",
    ],
    "weekly_alignment" => [
      "$home/barefoot_rob_master/event_templates/event_weekly-alignment_template.md",
    ],
    "walking_meditation" => [
      "$home/barefoot_rob_master/event_templates/event_walking_meditation_template.md",
    ],
    "barefoot_walk" => "walk_location_files",
    "quest_update" => [
      "$home/barefoot_rob_master/event_templates/niigata_2021_walking_update.md",
    ],
);

our %event_tag_hashes = (
    "blog_entry" => {"blog" => 1},
    "book_chapter" => {"book" => 1},
    "weekly_alignment" => {"weekly" => 1, "alignment" => 1, "event" => 1},
    "walking_meditation" => {"walk" => 1, "meditation" => 1, "event" => 1},
    "barefoot_walk" => {"walk" => 1, "barefoot" => 1, "event" => 1},
    "quest_update" => {"walk" => 1, "update" => 1, "quest" => 1},
);

our %event_title_prefixes = (
    "blog_entry" => "",
    "weekly_alignment" => "Weekly Alignment - ",
    "walking_meditation" => "",
    "barefoot_walk" => "",
    "book_chapter" => "",
    "quest_update" => "",
);
