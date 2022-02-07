package rpl::BLTConstants;

use strict;
use DateTime;

our %bold_life_tribe_themes = (
    1 => "CALLINGS",
    2 => "TRUTH",
    3 => "PURPOSE",
    4 => "RIGOR",
    5 => "WARRIOR was CONQUEST",
    6 => "JOY",
    7 => "CONNECTION",
    8 => "INTIMACY",
    9 => "SOVEREIGNTY",
    10 => "OFFERING",
    11 => "LEGACY",
    12 => "FREEDOM",
);

# photo URL on my site => credit URL
# todo: handle no credit URL
our %blt_truth_pics = (
    "https://b.robnugen.com/blog/2022/feather_sword_by_marcospsychic.png" =>
      "https://www.deviantart.com/marcospsychic/art/Marcos-Family-Sword-Crimson-Feather-Sword-Name-374302221",
    "https://b.robnugen.com/blog/2022/blt_truth_2_mastery.jpg" =>
      "https://pixabay.com/users/aytekin27-10747064/",
);

our %blt_pics_and_creds = (
    "TRUTH" => %blt_truth_pics,
);

our %bold_life_tribe_weekly_titles = (
    "CALLINGS" => [
       "What's Your Why?  (kinda freestyling here)",
       "Hearing the Call  (kinda freestyling here)",
       "Expand your Vision (or refine your focus?)",
       "Courage of Discovery (freestyling)",
    ],
    "TRUTH" => [
       "the feather and the sword",
       "the aspect of mastery",
       "white lies + soul truth",
       "4",
    ],
    "PURPOSE" => [
       "Awareness",
       "What lights you up?",
       "Who can I help?",
       "Emulation",
    ],
    "RIGOR" => [
       "Who don't I want to be?",
       "Triggers",
       "Inner Voices",
       "Clean Requests",
    ],
    "WARRIOR was CONQUEST" => [
       "1",
       "2",
       "Radical Compassion",
       "Radical Generosity",
    ],
    "JOY" => [
       "Embody",
       "Loving Life",
       "Joy Within Grief",
       "Generating Joy",
    ],
    "CONNECTION" => [
       "Body",
       "Ever Present Present",
       "People",
       "Context",
    ],
    "INTIMACY" => [
       "Courage",
       "Foundations",
       "Masks",
       "Self Acceptance",
    ],
    "SOVEREIGNTY" => [
       "Taking the wheel",
       "Projections Pleasures and Paths",
       "From Fear and Aversion",
       "From Ego",
    ],
    "OFFERING" => [
       "Your Deepest Gift",
       "Completing the Circle",
       "Your Being",
       "Order",
    ],
    "LEGACY" => [
       "Clarity",
       "Cleaning House",
       "Letting Go",
       "Bless and Release",
    ],
    "FREEDOM" => [
       "Free Consciousness",
       "Clearing the Attic",
       "From Expectations",
       "Freedom",
    ],
);
