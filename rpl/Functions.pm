package rpl::Functions;

use strict;
use DateTime;
use Date::Parse;

my $zone = "Asia/Tokyo";
our $zoffset = "+09:00";

our $dt = DateTime->now(
    time_zone  => $zone,
);

our $thedate = $dt->ymd;  # year-month-date (numeric).
our $thetime = $dt->hms;  # hour-min-sec    (numeric).
our $year    = $dt->year;
our $month   = $dt->month;
our $day     = $dt->day;
our $tz_date = $thedate . "T" . $thetime . $zoffset;

# poop out contents of file
# (will be used for BLT descriptions e.g. event_generators/blt/topics/02_truth_1_2022_02_07.txt)
sub return_contents_of_file($) {
  my ($full_path) = @_;
  local $/;  # makes changes local to this block
  undef $/;  # file slurp mode (default is "\n")
  open (ETF, "<", $full_path) or die "could not find template " . $full_path;
  my $content = <ETF>;
  close ETF;
  return $content;
}

# give me a file path for BLT topic, given a date
sub __blt_blurb_file_path_for_date($) {
  my ($dt) = @_;   # must be a DateTime or this function will be sad
  my $path_prefix = $rpl::Constants::blt_blurbs;
  my $blt_month = $dt->month;  # e.g. 2
  my $mm = $dt->strftime("%m");  # 02 just for the beginning of file name
  my $blt_week = $dt->weekday_of_month;  # https://metacpan.org/pod/DateTime#$dt-%3Eweekday_of_month
  my $theme = lc($rpl::BLTConstants::bold_life_tribe_themes{$blt_month});
  my $path = $dt->strftime("%Y_%m_%d");   ##  Sunday 30 May 2021
  my $path_to_blurb = $path_prefix."/".$mm."_".$theme."_".$blt_week."_".$path.".txt";
  print ("this should be a path like\n");
  print ("/home/thunderrabbit/barefoot_rob_master/event_generators/blt/blurbs/02_truth_1_2022_02_07.txt\n");
  print ($path_to_blurb."\n");
  return $path_to_blurb;
}

sub blt_blurb_for_date($) {
  my ($dt) = @_;   # must be a DateTime or next function will be sad
  my $blurb_filename = __blt_blurb_file_path_for_date($dt);
  return return_contents_of_file($blurb_filename);
}

sub std_in_logger() {
  my $si = <STDIN>;
  logthis($si);
  return $si;
}
sub logthis($) {
  my ($log_line) = @_;
  my $log = $rpl::Constants::event_generator_log;
  open(OUT, ">>", $log) or die "Could not open file '$log'";
  print OUT $log_line;
  close(OUT);
}
sub get_title($)
{
  my ($prefix) = @_;
  my $confirmed = 0;
  my $title;
  while (!$confirmed) {
    print "Enter title that comes after '" . $prefix . "'\n\n";
    $title = std_in_logger();
    $title =~ s/\s+/ /g;       # two spaces => one space
    $title =~ s/^\s+|\s+$//g;  # strip surrounding whitespace
    $title =~ s/^"(.*)"$/$1/;  # strip surrounding "s
    $title =~ s/^\s+|\s+$//g;  # strip surrounding whitespace  }
    $title = $prefix.$title;
    $confirmed = ask_confirm_string($title);
  }
  return $title;
}

sub get_date(@) {
  my ($dt_now, $desired_day_of_week) = @_;
  my $confirmed = 0;
  my $user_dt;   # will be returned once we confirm its value
  while (!$confirmed) {
    show_dates($dt_now, $desired_day_of_week);
    my $user_date = input_date($dt_now);
    my $user_time = input_time("primary time of event");  ## cannot send $user_date at this point because it has not been parsed into a timestamp object
    $user_dt = parse_user_date($user_date . " " . $user_time);
    $confirmed = ask_confirm_date($user_dt);
  }
  # return DateTime which has been parsed by `parse_user_date` and confirmed by user
  return ($user_dt);
}

sub get_time(@) {
  my ($time_description, $dt) = @_;
  my $confirmed = 0;
  my $user_dt;   # will be returned once we confirm its value
  while (!$confirmed) {
    my $user_time = input_time($time_description, $dt);
    $user_dt = parse_user_date($dt->ymd . " " . $user_time);  # Without ->ymd "T11:45:00" appends to the date
    $confirmed = 1; ##     ## eff confirming this; too boring   WAS  ask_confirm_date($user_dt);
  }
  # return DateTime which has been parsed by `parse_user_date`
  return ($user_dt);
}

sub show_dates(@) {
  my ($dt_now, $desired_day_of_week) = @_;
  my $dt = $dt_now->clone;      # don't mess with global date
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
  return 1;
}

sub ask_confirm_date($) {
  my ($dt) = @_;
  my $string_to_confirm = $dt->strftime("%A %d %B %Y %H:%M");   ##  Sunday 30 May 2021
  return ask_confirm_string($string_to_confirm);
}

sub ask_confirm_string($) {
  my ($string_to_confirm) = @_;
  my $confirmed = 0;
  print "\nIs this correct?  (yes/no)\n";
  print "  $string_to_confirm\n";
  while (1) {
    my $resp = std_in_logger();
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
  my ($dt) = @_;
  my $thedate = $dt->ymd;  # year-month-date (numeric).
  print "Input date of event: ($thedate)\n";
  my $user_date = std_in_logger();
  chomp($user_date);
  return length($user_date) ? $user_date : $thedate;
}

sub input_time(@) {
  my ($time_description, $dt) = @_;
  ## assume noon if nothing was sent
  my $default_time = "12:00";

  if($dt) {
    $default_time = $dt->strftime("%H:%M");  # 24 hour format
  }

  print "Input $time_description: ($default_time)\n";
  my $user_time = std_in_logger();
  chomp $user_time;
  return length($user_time) ? $user_time : $default_time;
}

sub parse_user_date($) {
  my ($user_date) = @_;
  print "in parse got this date: $user_date \n";
  my $epoch = str2time($user_date);    #  https://stackoverflow.com/a/7487117/194309
  return DateTime->from_epoch(epoch => $epoch, time_zone  => $zone);   # https://metacpan.org/pod/DateTime#DateTime-%3Efrom_epoch(-epoch-=%3E-$epoch,-...-)
}

sub prepend_book_title_based_on_date($) {
  my ($entry_date) = @_;
  print "in prepend_book_title_based_on_date, got this date: $entry_date \n";
  my $leading_zero = $entry_date->strftime("%m%d");
  return $leading_zero + 1000;         # code golf to produce 1419 for April 19th    The 1 prefix is for my book entry title convention
}

# https://stackoverflow.com/a/11369946/194309
sub ordinate($) {
  my ($cardinal) = @_;
  my $ordinal;
  if ($cardinal =~ /(?<!1)1$/) {
      $ordinal = 'st';
  } elsif ($cardinal =~ /(?<!1)2$/) {
      $ordinal = 'nd';
  } elsif ($cardinal =~ /(?<!1)3$/) {
      $ordinal = 'rd';
  } else {
      $ordinal = 'th';
  }
  return $cardinal.$ordinal;
}

sub kebab_case($) {
  my ($title) = @_;
      $title = lc($title);    # make title lowercase
      $title =~ s/[,\/\`\!\@\#\$\%\^\&\*\(\)\[\]\\\{\}\|\;\'\:\"\<\>\?\s]/-/g;
                              # replace special shell characters with hyphens (thanks to nooj)
      $title =~ s/-+/-/g;     # replace multiple hyphens with one (to match Hugo URLs)
  return $title;
}

sub get_tags(%) {
  my (%tags) = @_;
  my $confirmed = 0;
  my $tagstring;

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

      my $newtagstring = std_in_logger();
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
    $confirmed = ask_confirm_string($tagstring);

  }# !$confirmed

  return $tagstring;
}# get_tags()

# This was for event types but now can be used for any $type of @things
sub get_event_type(@) {
  my ($type_of_thing, @event_types) = @_;
  my $event_type;
  my $selected_type;

    print "\n";
    print "Possible $type_of_thing:\n";
    print "\n";

    my $num_event_types = scalar(@event_types);
    foreach my $ii (1..$num_event_types) {
      my $iipad = " " x (length($num_event_types) - length($ii));
      print "$iipad($ii) $event_types[$ii-1] $iipad($ii)\n";
    }# $ii

    $selected_type = "3";    ###  hardcode while testing
    print "Enter the number of the type you want to select: ($selected_type) ";
    my $raw_input = std_in_logger();

    $raw_input =~ s/\D+//g;     ## TODO: how to specify this ain't raw anymore?
    chomp($raw_input);
    $selected_type = length($raw_input) ? $raw_input : $selected_type;
    $event_type = $event_types[$selected_type-1];

    # confirm selected image
    print "\nCtrl-C if you ain't happy with your choice!\n";
    print "  event_type:     $event_type\n";
  return $event_type;
}

##  Return a list of files based on a directory
sub get_list_of_files_in_dir($) {
  my ($path_to_events) = @_;
  my @list_of_files;

  print "Returning events from " . $path_to_events . "\n";
  opendir DIR,$path_to_events;
  my @dir = readdir(DIR);
  close DIR;
  ## loop thanks to https://stackoverflow.com/a/1045814
  foreach(@dir){
      if (-f $path_to_events . "/" . $_ ){
        push (@list_of_files, $path_to_events . "/" . $_);    # will return a list of files
      }elsif(-d $path_to_events . "/" . $_){
        next if $_ =~ /^\.\.?$/;   ##  Skip . and .. https://stackoverflow.com/a/21203371
        print "ignoring directory " . $path_to_events . "/" . $_ . "\n";
      }else{
        print "ignoring non file non directory " . $path_to_events . "/" . $_ . "\n";
      }
  }

  return @list_of_files;
}

## Designed to simply remove the first bit of the path that is always the same
sub strip_path($) {
  my ($long_name_is_long) = @_;
  $long_name_is_long =~ s|/home/thunderrabbit/barefoot_rob_master/content/||g;
  return $long_name_is_long;
}
sub get_episode_image(@) {
  my ($title, @episode_images, @episode_thumbs) = @_;
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
    my $jj = std_in_logger();

    $episode_image = $episode_images[$jj-1];
    $episode_thumb = $episode_thumbs[$jj-1];

    # confirm selected image
    $confirmed = ask_confirm_string($episode_image);

  }# !$confirmed

  return ($episode_image,$episode_thumb);

}# get_episode_image()

sub image_URL_to_thumb_URL($) {
  my ($image_url) = @_;
  my $thumb_url;
  if($image_url =~ m{(.*)/([^/]+)}) {
    $thumb_url = "$1/thumbs/$2";
  }
  return $thumb_url;
}

sub get_image_url($) {
  my ($title) = @_;
  my $confirmed = 0;
  my ($episode_image,$episode_thumb);

  while (!$confirmed) {
    print "Please enter image URL for the following event:\n";
    print "  title:     $title\n";
    print "\n";

    $episode_image = std_in_logger();
    chomp $episode_image;
    $episode_thumb = image_URL_to_thumb_URL($episode_image);

    $confirmed = ask_confirm_string($episode_thumb);

  }# !$confirmed
  return ($episode_image,$episode_thumb);
}

sub get_image_credit() {
  my $image_credit;

  print "Please enter image credit URL if exists:\n";
  print "\n";

  $image_credit = std_in_logger();
  chomp $image_credit;

  return $image_credit;
}

sub extract_frontmatter($) {
  my ($markdown_file_contents) = @_;
  $markdown_file_contents =~ m!(?:---\n)(.*)(?:---)!ms;     # Gets multiple lines between rows of three hyphens
  my $frontmatter = $1;
  chomp $frontmatter;
  return $frontmatter;
}

sub wipe_frontmatter($) {
  my ($markdown_file_contents) = @_;
  $markdown_file_contents =~ m!(?:---\n)(?:.*)(?:---)(.*)!ms;     # Gets multiple lines after second row of three hyphens
  my $after_frontmatter = $1;
  chomp $after_frontmatter;
  return $after_frontmatter;
}

sub split_body(@) {
  my ($splitter, $body) = @_;

  my @body_parts = split /$splitter/,$body;

  return @body_parts;
}

sub this_looks_like_a_hash($) {
  my ($string) = @_;
  print $string . " looks like a hash\n" if $string !~ /^\//;  ## was =~ /^%/; but I took the % off the hashes to reference them by adding % back on
}

sub this_looks_like_a_file_path($) {
    my ($string) = @_;
    print $string . " looks like a file path\n" if $string =~ /^\//;
}

# https://www.perlmonks.org/?node_id=118961
# https://www.perlmonks.org/?node_id=455955;displaytype=displaycode
sub is_array($) {
    my ($ref) = @_;
    # Firstly arrays need to be references, throw
    #  out non-references early.
    return 0 unless ref $ref;

    # Now try and eval a bit of code to treat the
    #  reference as an array.  If it complains
    #  in the 'Not an ARRAY reference' then we're
    #  sure it's not an array, otherwise it was.
    eval {
      my $a = @$ref;
    };
    if ($@=~/^Not an ARRAY reference/) {
      return 0;
    } elsif ($@) {
      die "Unexpected error in eval: $@\n";
    } else {
      return 1;
    }

  }
