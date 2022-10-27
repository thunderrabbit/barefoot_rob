package rpl::Constants;

use strict;
use DateTime;

our $home = $ENV{HOME};    # https://stackoverflow.com/a/1451420/194309

my $dt = DateTime->now();

my $repo_directory = $ENV{BAREFOOT_ROB_MASTER} || "$home/barefoot_rob_master";
my $templates = "$repo_directory/event_templates";
our $blt_blurbs = "$repo_directory/event_generators/blt/blurbs";
our $event_generator_log = "$repo_directory/event_generators/" . $dt->ymd("_") . "_log.txt";
our $content_directory = "$repo_directory/content";
our $blog_directory = "/blog";    #  appended to $content_directory when writing actual file.
our $events_directory = "/events";    #  appended to $content_directory when writing actual file.
our $niigata_walk_dir = "/quests/walk-to-niigata";    #  appended to $content_directory when writing actual file.
our $slow_down_book_dir = "/books/slow-down";    #  appended to $content_directory when writing actual file.

our %walk_location_files = (
    "yoyogi_park" => [
      "$templates/walk_and_talk/yoyogi_park/yoyogi_park.en.md",
      "$templates/walk_and_talk/yoyogi_park/yoyogi_park.ja.md",
      "$templates/walk_and_talk/yoyogi_park/yoyogi_park.facebook.txt",
      "$templates/walk_and_talk/yoyogi_park/yoyogi_park.meetup.txt",
      "$templates/walk_and_talk/yoyogi_park/yoyogi_park.twitter.txt",
      "$templates/walk_and_talk/___.t-07days_reminder.txt",
      "$templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "rinko_park" => [
      "$templates/walk_and_talk/rinko_park/rinko_park.en.md",
      "$templates/walk_and_talk/rinko_park/rinko_park.ja.md",
      "$templates/walk_and_talk/rinko_park/rinko_park.facebook.txt",
      "$templates/walk_and_talk/rinko_park/rinko_park.meetup.txt",
      # "$templates/walk_and_talk/rinko_park/rinko_park.twitter.txt",
      "$templates/walk_and_talk/___.t-07days_reminder.txt",
      "$templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "rinshi_no_mori" => [
      "$templates/walk_and_talk/rinshi_no_mori/rinshi_no_mori.en.md",
      "$templates/walk_and_talk/rinshi_no_mori/rinshi_no_mori.ja.md",
      "$templates/walk_and_talk/rinshi_no_mori/rinshi_no_mori.facebook.txt",
      "$templates/walk_and_talk/rinshi_no_mori/rinshi_no_mori.meetup.txt",
      # "$templates/walk_and_talk/rinshi_no_mori/rinshi_no_mori.twitter.txt",
      "$templates/walk_and_talk/___.t-07days_reminder.txt",
      "$templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "karakida_tama_center" => [
      "$templates/walk_and_talk/karakida_to_tama_center/karakida_tama_center.en.md",
      "$templates/walk_and_talk/karakida_to_tama_center/karakida_tama_center.ja.md",
      "$templates/walk_and_talk/karakida_to_tama_center/karakida_tama_center.facebook.txt",
      "$templates/walk_and_talk/karakida_to_tama_center/karakida_tama_center.meetup.txt",
      # "$templates/walk_and_talk/karakida_to_tama_center/karakida_tama_center.twitter.txt",
      "$templates/walk_and_talk/___.t-07days_reminder.txt",
      "$templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "izumi_tamagawa" => [
      "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.en.md",
      "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.ja.md",
      "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.facebook.txt",
      "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.meetup.txt",
      "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.message.txt",
      "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.twitter.txt",
      "$templates/walk_and_talk/___.t-07days_reminder.txt",
      "$templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "izumi_tamagawa_full_moon" => [
      "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.en.md",
      "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.ja.md",
      "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.facebook.txt",
      "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.meetup.txt",
      "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.message.txt",
      "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.twitter.txt",
      "$templates/walk_and_talk/___.t-07days_reminder.txt",
      "$templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "izumi_tamagawa_new_moon" => [
      "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_new_moon.en.md",
      # "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_new_moon.ja.md",
      "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_new_moon.facebook.txt",
      "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_new_moon.meetup.txt",
      "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_new_moon.message.txt",
      "$templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_new_moon.twitter.txt",
      "$templates/walk_and_talk/___.t-07days_reminder.txt",
      "$templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "shin_yuri_art_park" => [
      "$templates/walk_and_talk/shin_yuri_art_park/shin_yuri_art_park.en.md",
      "$templates/walk_and_talk/shin_yuri_art_park/shin_yuri_art_park.ja.md",
      "$templates/walk_and_talk/shin_yuri_art_park/shin_yuri_art_park.facebook.txt",
      "$templates/walk_and_talk/shin_yuri_art_park/shin_yuri_art_park.meetup.txt",
      "$templates/walk_and_talk/shin_yuri_art_park/shin_yuri_art_park.twitter.txt",
      "$templates/walk_and_talk/___.t-07days_reminder.txt",
      "$templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "shin_yuri_manpukuji_park" => [
      "$templates/walk_and_talk/shin_yuri_manpukuji_park/shin_yuri_manpukuji_park.en.md",
      # "$templates/walk_and_talk/shin_yuri_manpukuji_park/shin_yuri_manpukuji_park.ja.md",
      # "$templates/walk_and_talk/shin_yuri_manpukuji_park/shin_yuri_manpukuji_park.facebook.txt",
      # "$templates/walk_and_talk/shin_yuri_manpukuji_park/shin_yuri_manpukuji_park.meetup.txt",
      # "$templates/walk_and_talk/shin_yuri_manpukuji_park/shin_yuri_manpukuji_park.twitter.txt",
      "$templates/walk_and_talk/___.t-07days_reminder.txt",
      "$templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "todoroki_valley" => [
      "$templates/walk_and_talk/todoroki_valley/todoroki_valley.en.md",
      # "$templates/walk_and_talk/todoroki_valley/todoroki_valley.ja.md",
      # "$templates/walk_and_talk/todoroki_valley/todoroki_valley.facebook.txt",
      # "$templates/walk_and_talk/todoroki_valley/todoroki_valley.meetup.txt",
      # "$templates/walk_and_talk/todoroki_valley/todoroki_valley.twitter.txt",
      "$templates/walk_and_talk/___.t-07days_reminder.txt",
      "$templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "hossawa_falls" => [
      "$templates/walk_and_talk/hossawa_falls/hossawa_falls.en.md",
      "$templates/walk_and_talk/hossawa_falls/hossawa_falls.ja.md",
      # "$templates/walk_and_talk/hossawa_falls/hossawa_falls.facebook.txt",
      # "$templates/walk_and_talk/hossawa_falls/hossawa_falls.meetup.txt",
      "$templates/walk_and_talk/___.t-07days_reminder.txt",
      "$templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
);

#  ///   MUST ALSO DO %event_output_directories   ///
our %event_template_files = (
    "blog_entry" => [
      "$templates/blog_template.md",
    ],
    "book_chapter" => [
      "$templates/book_chapter_template.md",
    ],
    "weekly_alignment" => [
      "$templates/event_weekly-alignment_template.md",
    ],
    "mkp_family" => [
      "$templates/mkp/mkp_yoyogi_family_hangout_slack.md",
      "$templates/walk_and_talk/___.t-07days_reminder.txt",
      "$templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "walking_meditation" => [
      "$templates/event_walking_meditation_template.md",
    ],
    "barefoot_walk" => "walk_location_files",
    "yo_i_wanna_copy" => "previous_generators",
    "quest_update" => [
      "$templates/niigata_2021_walking_update.md",
    ],
    "bold_life_tribe" => [
      "$templates/bold-life-tribe/weekly-online-events.en.md",
    ],
);
#  ///   MUST ALSO DO %event_output_directories   ///

our %event_day_of_week = (
    "blog_entry" => 3,
    "book_chapter" => 3,
    "weekly_alignment" => 3,
    "walking_meditation" => 3,
    "yoyogi_park" => 6,
    "rinko_park" => 6,
    "rinshi_no_mori" => 6,
    "izumi_tamagawa" => 6,
    "izumi_tamagawa_full_moon" => 1,
    "izumi_tamagawa_new_moon" => 1,
    "shin_yuri_art_park" => 4,
    "shin_yuri_manpukuji_park" => 3,
    "hossawa_falls" => 7,
    "quest_update" => 3,
    "bold_life_tribe" => 1,
);

our %event_primary_time = (
    "yoyogi_park" => "12:00",
    "rinko_park" => "13:00",
    "rinshi_no_mori" => "12:00",
    "izumi_tamagawa" => "13:00",
    "izumi_tamagawa_full_moon" => "20:00",
    "izumi_tamagawa_new_moon" => "20:00",
    "shin_yuri_art_park" => "14:00",
    "shin_yuri_manpukuji_park" => "13:00",
    "hossawa_falls" => "13:00",
);

our %gather_minutes_before_event = (
    "yoyogi_park" => "15",
    "rinko_park" => "15",
    "rinshi_no_mori" => "30",
    "izumi_tamagawa" => "15",
    "izumi_tamagawa_full_moon" => "15",
    "izumi_tamagawa_new_moon" => "15",
    "shin_yuri_art_park" => "30",
    "shin_yuri_manpukuji_park" => "30",
    "hossawa_falls" => "30",
);

our %event_locations = (
    "yoyogi_park" => "Yoyogi Park (Harajuku Gate)",
    "rinko_park" => "Rinko Park, Yokohama",
    "rinshi_no_mori" => "Rinshi-no-Mori Park, Meguro",
    "karakida_tama_center" => "between Karakida and Tama Center",
    "izumi_tamagawa" => "Izumi Tamagawa (Odakyu Line)",
    "izumi_tamagawa_full_moon" => "Izumi Tamagawa for full moon 満月",
    "izumi_tamagawa_new_moon" => "Izumi Tamagawa for new moon 新月",
    "shin_yuri_art_park" => "Shin Yuri Art Park (near Shinyurigaoka)",
    "shin_yuri_manpukuji_park" => "Manpukuji Hiyama Park (near Shinyurigaoka)",
    "hossawa_falls" => "Nishitama District: Hossawa Falls, Mt Bonbori, and Seoto foot bath",
);

# https://stackoverflow.com/questions/350018/how-can-i-combine-hashes-in-perl
# not used because https://github.com/thunderrabbit/barefoot_rob/issues/4
my %walk_and_talk_tags = ("walk" => 1, "裸足のロブ" => 1, "はだし" => 1, "barefoot" => 1, "event" => 1, "Barefoot Rob" => 1);

our %event_tag_hashes = (
    "blog_entry" => {"blog" => 1},
    "book_chapter" => {"book" => 1, "walk" => 1},
    "weekly_alignment" => {"weekly" => 1, "alignment" => 1, "event" => 1},
    "walking_meditation" => {"walk" => 1, "meditation" => 1, "event" => 1},
    "karakida_tama_center" => {%walk_and_talk_tags, ("Tama Center" => 1, "Karakida" => 1, "多摩センター駅" => 1, "唐木田駅" => 1)},
    "rinshi_no_mori" => {%walk_and_talk_tags, ("meguro" => 1, "rinshi-no-mori" => 1, "林試の森公園" => 1)},
    "rinko_park" => {%walk_and_talk_tags, ("Yokohama" => 1, "rinko-park" => 1, "臨港パーク" => 1)},
    "shin_yuri_art_park" => {%walk_and_talk_tags, ("art_park" => 1, "新百合ヶ丘駅" => 1)},
    "shin_yuri_manpukuji_park" => {%walk_and_talk_tags, ("manpukuji" => 1, "hiyama" => 1, "万福寺檜山公園" => 1, "新百合ヶ丘駅" => 1)},
    "todoroki_valley" => {%walk_and_talk_tags, ("todoroki" => 1, "等々力渓谷" => 1, "city" => 1)},
    "hossawa_falls" => {%walk_and_talk_tags, ("hossawa" => 1, "nishitama" => 1, "払沢の滝" => 1, "bonbori" => 1, "盆堀山" => 1)},
    "izumi_tamagawa" => {%walk_and_talk_tags, ("izumi-tamagawa" => 1, "riverside" => 1, "blue-cafe" => 1, "tamagawa" => 1, "多摩川" => 1)},
    "izumi_tamagawa_full_moon" => {%walk_and_talk_tags, ("izumi-tamagawa" => 1, "riverside" => 1, "full moon" => 1, "tamagawa" => 1, "多摩川" => 1, "満月" => 1)},
    "izumi_tamagawa_new_moon" => {%walk_and_talk_tags, ("izumi-tamagawa" => 1, "riverside" => 1, "new moon" => 1, "tamagawa" => 1, "多摩川" => 1, "新月" => 1)},
    "yoyogi_park" => {%walk_and_talk_tags, ("yoyogi" => 1, "代々木公園" => 1)},
    "quest_update" => {"walk" => 1, "update" => 1, "quest" => 1},
    "bold_life_tribe" => {"bold-life-tribe" => 1, "blt" => 1, "event" => 1, "online" => 1},
);

our %event_title_prefixes = (
    "weekly_alignment" => "Weekly Alignment - ",
    "bold_life_tribe" => "Bold Life Tribe",
);
