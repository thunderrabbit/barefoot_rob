package rpl::Constants;

use strict;
use DateTime;

our $home = $ENV{HOME};    # https://stackoverflow.com/a/1451420/194309

my $dt = DateTime->now();

my $repo_directory = $ENV{BAREFOOT_ROB_MASTER} || "$home/barefoot_rob_master";
my $event_templates = "$repo_directory/templates/event_templates";
my $writing_templates = "$repo_directory/templates/writing_templates";
our $blt_blurbs = "$repo_directory/event_generators/blt/blurbs";
our $event_generator_log = "$repo_directory/event_generators/" . $dt->ymd("_") . "_log.txt";
our $content_directory = "$repo_directory/content";
our $blog_directory = "/blog";    #  appended to $content_directory when writing actual file.
our $events_directory = "/events";    #  appended to $content_directory when writing actual file.
our $niigata_walk_dir = "/quests/walk-to-niigata";    #  appended to $content_directory when writing actual file.
our $slow_down_book_dir = "/books/slow-down";    #  appended to $content_directory when writing actual file.

our %cuddle_party_files = (
    "sun_lily" => [
      "$event_templates/cuddle_party/sun_lily/sun_lily.en.md",
      "$event_templates/cuddle_party/sun_lily/sun_lily.meetup.txt",
      "$event_templates/cuddle_party/sun_lily/sun_lily.eventbrite.txt",
      "$event_templates/cuddle_party/sun_lily/sun_lily.facebook.txt",
      "$event_templates/cuddle_party/sun_lily/sun_lily.peatix.txt",
    ],
);

our %book_chapter_files = (
    "realtime_book_chapter" => [
      "$writing_templates/realtime_book_chapter_template.md",
    ],
    "otter_book_chapter" => [
      "$writing_templates/otter_book_chapter_template.md",
    ],
);

our %walk_location_files = (
    "yoyogi_park" => [
      "$event_templates/walk_and_talk/yoyogi_park/yoyogi_park.en.md",
      "$event_templates/walk_and_talk/yoyogi_park/yoyogi_park.ja.md",
      "$event_templates/walk_and_talk/yoyogi_park/yoyogi_park.facebook.txt",
      "$event_templates/walk_and_talk/yoyogi_park/yoyogi_park.meetup.txt",
      "$event_templates/walk_and_talk/___.t-07days_reminder.txt",
      "$event_templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "rinko_park" => [
      "$event_templates/walk_and_talk/rinko_park/rinko_park.en.md",
      "$event_templates/walk_and_talk/rinko_park/rinko_park.ja.md",
      "$event_templates/walk_and_talk/rinko_park/rinko_park.facebook.txt",
      "$event_templates/walk_and_talk/rinko_park/rinko_park.meetup.txt",
      "$event_templates/walk_and_talk/___.t-07days_reminder.txt",
      "$event_templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "porta_to_rinko_park" => [
      "$event_templates/walk_and_talk/rinko_park/porta_to_rinko_park.en.md",
      "$event_templates/walk_and_talk/rinko_park/porta_to_rinko_park.ja.md",
      "$event_templates/walk_and_talk/rinko_park/porta_to_rinko_park.facebook.txt",
      "$event_templates/walk_and_talk/rinko_park/porta_to_rinko_park.meetup.txt",
    ],
    "rinshi_no_mori" => [
      "$event_templates/walk_and_talk/rinshi_no_mori/rinshi_no_mori.en.md",
      "$event_templates/walk_and_talk/rinshi_no_mori/rinshi_no_mori.ja.md",
      "$event_templates/walk_and_talk/rinshi_no_mori/rinshi_no_mori.facebook.txt",
      "$event_templates/walk_and_talk/rinshi_no_mori/rinshi_no_mori.meetup.txt",
      "$event_templates/walk_and_talk/___.t-07days_reminder.txt",
      "$event_templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "karakida_tama_center" => [
      "$event_templates/walk_and_talk/karakida_to_tama_center/karakida_tama_center.en.md",
      "$event_templates/walk_and_talk/karakida_to_tama_center/karakida_tama_center.ja.md",
      "$event_templates/walk_and_talk/karakida_to_tama_center/karakida_tama_center.facebook.txt",
      "$event_templates/walk_and_talk/karakida_to_tama_center/karakida_tama_center.meetup.txt",
      "$event_templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "izumi_tamagawa" => [
      "$event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.en.md",
      "$event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.ja.md",
      "$event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.facebook.txt",
      "$event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.meetup.txt",
      "$event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.message.txt",
      "$event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa.twitter.txt",
      "$event_templates/walk_and_talk/___.t-07days_reminder.txt",
      "$event_templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "izumi_tamagawa_full_moon" => [
      "$event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.en.md",
      "$event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.ja.md",
      "$event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.facebook.txt",
      "$event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.meetup.txt",
      "$event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.message.txt",
      "$event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_full_moon.twitter.txt",
      "$event_templates/walk_and_talk/___.t-07days_reminder.txt",
      "$event_templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "izumi_tamagawa_new_moon" => [
      "$event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_new_moon.en.md",
      "$event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_new_moon.facebook.txt",
      "$event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_new_moon.meetup.txt",
      "$event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_new_moon.message.txt",
      "$event_templates/walk_and_talk/izumi_tamagawa/izumi_tamagawa_new_moon.twitter.txt",
      "$event_templates/walk_and_talk/___.t-07days_reminder.txt",
      "$event_templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "shin_yuri_art_park" => [
      "$event_templates/walk_and_talk/shin_yuri_art_park/shin_yuri_art_park.en.md",
      "$event_templates/walk_and_talk/shin_yuri_art_park/shin_yuri_art_park.ja.md",
      "$event_templates/walk_and_talk/shin_yuri_art_park/shin_yuri_art_park.facebook.txt",
      "$event_templates/walk_and_talk/shin_yuri_art_park/shin_yuri_art_park.meetup.txt",
      "$event_templates/walk_and_talk/shin_yuri_art_park/shin_yuri_art_park.twitter.txt",
      "$event_templates/walk_and_talk/___.t-07days_reminder.txt",
      "$event_templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "shin_yuri_manpukuji_park" => [
      "$event_templates/walk_and_talk/shin_yuri_manpukuji_park/shin_yuri_manpukuji_park.en.md",
      "$event_templates/walk_and_talk/___.t-07days_reminder.txt",
      "$event_templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "todoroki_valley" => [
      "$event_templates/walk_and_talk/todoroki_valley/todoroki_valley.en.md",
      "$event_templates/walk_and_talk/___.t-07days_reminder.txt",
      "$event_templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "hossawa_falls" => [
      "$event_templates/walk_and_talk/hossawa_falls/hossawa_falls.en.md",
      "$event_templates/walk_and_talk/hossawa_falls/hossawa_falls.ja.md",
      "$event_templates/walk_and_talk/___.t-07days_reminder.txt",
      "$event_templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "hikarie_to_foot_bath" => [
      "$event_templates/walk_and_talk/hikarie_to_foot_bath/hikarie_to_foot_bath.en.md",
    ],
);

#  ///   MUST ALSO DO %event_output_directories   ///
our %event_template_files = (
    "blog_entry" => [
      "$writing_templates/blog_template.md",
    ],
    "weekly_alignment" => [
      "$event_templates/event_weekly-alignment_template.md",
    ],
    "mkp_family" => [
      "$event_templates/mkp/mkp_yoyogi_family_hangout_slack.md",
      "$event_templates/walk_and_talk/___.t-07days_reminder.txt",
      "$event_templates/walk_and_talk/___.t-14days_reminder.txt",
    ],
    "walking_meditation" => [
      "$event_templates/event_walking_meditation_template.md",
    ],
    "barefoot_walk" => "walk_location_files",
    "book_chapter" => "book_chapter_files",
    "cuddle_party" => "cuddle_party_files",
    "yo_i_wanna_copy" => "previous_generators",
    "quest_update" => [
      "$writing_templates/niigata_2021_walking_update.md",
    ],
    "bold_life_tribe" => [
      "$event_templates/bold-life-tribe/weekly-online-events.en.md",
    ],
);
#  ///   MUST ALSO DO %event_output_directories   ///

our %event_day_of_week = (
    "blog_entry" => 3,
    "realtime_book_chapter" => 3,
    "weekly_alignment" => 3,
    "walking_meditation" => 3,
    "yoyogi_park" => 6,
    "rinko_park" => 6,
    "rinshi_no_mori" => 6,
    "izumi_tamagawa" => 6,
    "izumi_tamagawa_full_moon" => 1,
    "izumi_tamagawa_new_moon" => 1,
    "shin_yuri_art_park" => 6,
    "shin_yuri_manpukuji_park" => 3,
    "hossawa_falls" => 7,
    "hikarie_to_foot_bath" => 6,
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
    "hikarie_to_foot_bath" => "13:00",
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
    "hikarie_to_foot_bath" => "15",
);

our %event_locations = (
    "yoyogi_park" => "Yoyogi Park (Harajuku Gate)",
    "porta_to_rinko_park" => "Rinko Park, Yokohama",
    "rinko_park" => "Rinko Park, Yokohama",
    "rinshi_no_mori" => "Rinshi-no-Mori Park, Meguro",
    "karakida_tama_center" => "between Karakida and Tama Center",
    "izumi_tamagawa" => "Izumi Tamagawa (Odakyu Line)",
    "izumi_tamagawa_full_moon" => "Izumi Tamagawa for full moon 満月",
    "izumi_tamagawa_new_moon" => "Izumi Tamagawa for new moon 新月",
    "shin_yuri_art_park" => "Shin Yuri Art Park (near Shinyurigaoka)",
    "shin_yuri_manpukuji_park" => "Manpukuji Hiyama Park (near Shinyurigaoka)",
    "sun_lily" => "SunLily Yoga Studio",
    "hossawa_falls" => "Nishitama District: Hossawa Falls, Mt Bonbori, and Seoto foot bath",
    "hikarie_to_foot_bath" => "Shibuya District: from Hikarie looping around to foot bath and Hachiko"
);

# https://stackoverflow.com/questions/350018/how-can-i-combine-hashes-in-perl
# not used because https://github.com/thunderrabbit/barefoot_rob/issues/4
my %walk_and_talk_tags = ("walk" => 1, "裸足のロブ" => 1, "はだし" => 1, "barefoot" => 1, "event" => 1, "Barefoot Rob" => 1);
my %cuddle_party_tags = ("communication" => 1, "Barefoot Rob" => 1, "裸足のロブ" => 1, "cuddle-party" => 1, "workshop" => 1);

our %event_tag_hashes = (
    "blog_entry" => {"blog" => 1},
    "realtime_book_chapter" => {"book" => 1, "walk" => 1},
    "otter_book_chapter" => {"book" => 1, "otter" => 1},
    "weekly_alignment" => {"weekly" => 1, "alignment" => 1, "event" => 1},
    "walking_meditation" => {"walk" => 1, "meditation" => 1, "event" => 1},
    "karakida_tama_center" => {%walk_and_talk_tags, ("Tama Center" => 1, "Karakida" => 1, "多摩センター駅" => 1, "唐木田駅" => 1)},
    "rinshi_no_mori" => {%walk_and_talk_tags, ("meguro" => 1, "rinshi-no-mori" => 1, "林試の森公園" => 1)},
    "rinko_park" => {%walk_and_talk_tags, ("Yokohama" => 1, "rinko-park" => 1, "臨港パーク" => 1)},
    "porta_to_rinko_park" => {%walk_and_talk_tags, ("Yokohama" => 1, "Porta" => 1, "rinko-park" => 1, "臨港パーク" => 1)},
    "shin_yuri_art_park" => {%walk_and_talk_tags, ("art_park" => 1, "新百合ヶ丘駅" => 1)},
    "shin_yuri_manpukuji_park" => {%walk_and_talk_tags, ("manpukuji" => 1, "hiyama" => 1, "万福寺檜山公園" => 1, "新百合ヶ丘駅" => 1)},
    "sun_lily" => {%cuddle_party_tags, ("sunlily" => 1, "ikejiri-ohashi" => 1)},
    "todoroki_valley" => {%walk_and_talk_tags, ("todoroki" => 1, "等々力渓谷" => 1, "city" => 1)},
    "hikarie_to_foot_bath" => {%walk_and_talk_tags, ("shibuya" => 1, "hikarie" => 1, "toyoko" => 1)},
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
