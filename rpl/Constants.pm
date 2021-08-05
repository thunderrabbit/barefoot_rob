package rpl::Constants;

use strict;

our $home = $ENV{HOME};    # https://stackoverflow.com/a/1451420/194309

our $content_directory = "$home/barefoot_rob/content";
our $blog_directory = "/blog";    #  appended to $content_directory when writing actual file.
our $events_directory = "/events";    #  appended to $content_directory when writing actual file.
our $niigata_walk_dir = "/quests/walk-to-niigata";    #  appended to $content_directory when writing actual file.
our $slow_down_book_dir = "/quests/slow-down";    #  appended to $content_directory when writing actual file.

our %event_template_files = (
    "blog_entry" => "$home/barefoot_rob/templates/blog_template.txt",
    "book_chapter" => "$home/barefoot_rob/templates/book_chapter_template.txt",
    "weekly_alignment" => "$home/barefoot_rob/templates/event_weekly-alignment_template.txt",
    "walking_meditation" => "$home/barefoot_rob/templates/event_walking_meditation_template.txt",
    "quest_update" => "$home/barefoot_rob/templates/niigata_2021_walking_update.txt",
);

our %event_tag_hashes = (
    "blog_entry" => {"blog" => 1},
    "book_chapter" => {"book" => 1},
    "weekly_alignment" => {"weekly" => 1, "alignment" => 1, "event" => 1},
    "walking_meditation" => {"walk" => 1, "meditation" => 1, "event" => 1},
    "quest_update" => {"walk" => 1, "update" => 1, "quest" => 1},
);

our %event_title_prefixes = (
    "blog_entry" => "",
    "weekly_alignment" => "Weekly Alignment - ",
    "walking_meditation" => "",
    "book_chapter" => "",
    "quest_update" => "",
);
