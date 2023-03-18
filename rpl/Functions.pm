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
sub return_contents_of_file(@) {
  my ($full_path,$ignore_error) = @_;
  local $/;  # makes changes local to this block
  undef $/;  # file slurp mode (default is "\n")
  open (ETF, "<", $full_path) or $ignore_error or die "could not find file " . $full_path;
  my $content = <ETF>;
  close ETF;
  return $content;
}

# This is used to get templates of walking events
sub return_contents_of_array_of_files(@) {
  my @event_paths_array = @_;
  my %event_templates;   ## 'bout to get multiple templates (one per language, social network)

  ## Load each template in the selected array
  foreach(@event_paths_array) {
    $_ =~ /[^\.]+(.*)/;    ## Grab extension, from first period onward
    my $extension = $1;

    $event_templates{$extension} = rpl::Functions::return_contents_of_file($_);
  }

  return %event_templates;
}

sub get_hash_of_recent_generators(@) {
  my ($first_date, $last_date) = @_;
  unless($first_date && $last_date) {
    print "\n\nNEED TWO DATES: today and a month ago or so\n\n";
  }
  print "First date = $first_date\n";
  print "Last date = $last_date\n";


  my ($dt) = @_;   # must be a DateTime or this function will be sad
  my $path_prefix = "/home/thunderrabbit/barefoot_rob_master/event_generators";
  my $this_year = $dt->year();  # e.g. 2021/05/03
  print "Returning paths with prefix $path_prefix/$this_year\n\n";

  my ($path_portion,$file_portion) = split_on_final_slash("$path_prefix/$this_year");
  my @mess_of_files = get_list_of_files_in_dir($path_portion,$file_portion);
  my %hot_mess_of_files;
  my $file_count = 0;
  foreach (sort @mess_of_files) {
    $file_count ++;
    $hot_mess_of_files{$_} = $_;
  }
  return %hot_mess_of_files;

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
  return return_contents_of_file($blurb_filename,1);
}

sub blt_create_empty_blurb_file_for_date($) {
  my ($dt) = @_;   # must be a DateTime or next function will be sad
  my $blurb_filename = __blt_blurb_file_path_for_date($dt);
  open (ETF, ">", $blurb_filename);
  close ETF;
}

# give me an array of file paths from which chapter content will be pulled
sub __book_content_file_paths_for_date($) {
  my ($dt) = @_;   # must be a DateTime or this function will be sad
  my $path_prefix = "/home/thunderrabbit/barefoot_rob_master/content/quests/walk-to-niigata"; # $rpl::Constants::blt_blurbs;
  my $chapter_date = $dt->date("/");  # e.g. 2021/05/03
  print "Returning paths with prefix $path_prefix/$chapter_date\n\n";
  print "Okay now need to get a list of files with ^^^^ prefix\n\n";
  my ($path_portion,$dd_portion) = split_on_final_slash("$path_prefix/$chapter_date");
  return get_list_of_files_in_dir($path_portion,$dd_portion);
}

sub split_on_final_slash($) {
  my ($full_path) = @_;
  # https://stackoverflow.com/a/2469384/194309
  $full_path =~ m|(.*)/(.*)|;   # greedy match up to / then after same /
  return ($1, $2)
}

sub return_book_chapter_for_files(@) {
  my %date_keyed_content_hash;
  # should open a list(?) of file paths and return their concatenated content
  # STEPS(?)
  # For each path
  #   Open file
  #   Process file
  #     Find date in YAML header
  #     Find title in YAML header
  #     Find location in YAML header
  #   Sort according to date
  # For each date
  #   Rewrite lines at top of file:
  #       #### DATE\n\n    title\n    location
  #   append to output (in date order)
  # Return contents, sorted by date
  print "Processing these files:\n" . join("\n",@_) . "\n\n";
  # For each path
  foreach my $filepath (@_) {
    #   Open file
    print("$filepath\n");
    my $unprocessed_file = return_contents_of_file($filepath);

    print ("$unprocessed_file\n\n");
    #   Process file
    my $file_frontmatter = extract_frontmatter($unprocessed_file);
    my $file_content = wipe_frontmatter($unprocessed_file);

    print($file_frontmatter);
    print("$file_content\n");
    my($file_date,$file_title,$post_location);
    #     Find date in YAML header
    if($file_frontmatter =~ m/date: (.*)/) {   # dates may have single, double, or no quotes
      $file_date = $1;
    }
    print("FILE DATE: $file_date\n");
    #     Find title in YAML header   # Grab whole line to mark it as meta info
    if($file_frontmatter =~ m/(title: .*)/) {
      $file_title = $1;
    }
    print("FILE TITLE: $file_title\n");
    #     Find location in YAML header  # Grab whole line to mark it as meta info
    if($file_frontmatter =~ m/(location: .*)/) {
      $post_location = $1;
    }
    print("POST LOCATION: $post_location\n");
    # For each date
    #   Rewrite lines at top of file:
    #       #### DATE\n\n    title\n    location
    my $dated_output_thing = "#### " . $file_date . "\n\n" .
                             "    " . $file_title . "\n";
    if($post_location) {
      $dated_output_thing .= "    " . $post_location . "\n";
    }

    $dated_output_thing .= $file_content . "\n";
    print("$dated_output_thing");
    $date_keyed_content_hash{$file_date} = $dated_output_thing;
  }
  my $book_chapter_output;
  #   Sort according to date
  foreach my $file_date_key (sort keys %date_keyed_content_hash) {
    #   append to output (in date order)
    $book_chapter_output .= $date_keyed_content_hash{$file_date_key} . "\n";
  }
  # Return contents, sorted by date
  return $book_chapter_output;
}

sub book_content_for_date($) {
  my ($dt) = @_;   # must be a DateTime or next function will be sad
  my @content_files_regex = __book_content_file_paths_for_date($dt);   # must return an ARRAY of file paths (I think (22 Apr 2022))
  return return_book_chapter_for_files(@content_files_regex);   # takes an ARRAY of file paths (I think (22 Apr 2022))
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
  my ($dt_now, $desired_day_of_week, $desired_event_time, $get_time) = @_;
  my $confirmed = 0;
  my $user_dt;   # will be returned once we confirm its value
  while (!$confirmed) {
    # send dt_now so we know from what date to start showing future dates
    show_dates($dt_now, $desired_day_of_week);
    my $user_date = input_date($dt_now);
    my $user_time;
    if($get_time) {
      $user_time = input_time("primary time of event", 0, $desired_event_time);  ## send 0 instead of timestamp, then string for gathering time eg "13:00"
    } else {
      $user_time = $desired_event_time;
    }
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
  my ($time_description, $dt, $desired_event_time) = @_;
  ## assume noon if nothing was sent
  my $default_time = $desired_event_time || "12:00";

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

# Convert 1 to 1st, 2 to 2nd, 3 to 3rd, 4 to 4th, etc
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
sub choose_from_list_of(@) {
  my ($type_of_thing, @event_types) = @_;   # First parameter is for human to know what types of things are in the list
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
    print "Enter the number of the type you want to select, or its exact name: ($selected_type) ";
    my $raw_input = std_in_logger();
    
    # clean up the input a little  
    chomp($raw_input);
    $raw_input = lc($raw_input);
    $raw_input =~ s/[^[:alnum:]_]+//g;
       
    if ($raw_input =~ /^\d+$/) {
      # input is all digits.  assume it's an index
      
      $raw_input =~ s/\D+//g;     ## TODO: how to specify this ain't raw anymore?
      $selected_type = length($raw_input) ? $raw_input : $selected_type;
      $event_type = $event_types[$selected_type-1];
        
    } else {
      # input was an event type string
       
      # change this regex to make it match, for example, substrings 
      my @matches = grep { $_ =~ /^\Q$raw_input\E$/ } @event_types;
      my $num_matches = scalar(@matches);
        
      if (1 == $num_matches) {
        $event_type = $matches[0];
      } else {

        # change this to whatever desired behavior you like, eg loop to top and try again.
        die(
          "error: Fix event_locations matched $num_matches event types: <"
          . (join ", ", @matches)
          . ">"
        );
      }
    }

    # confirm selected image
    print "\nCtrl-C if you ain't happy with your choice!\n";
    print "  event_type:     $event_type\n";
  return $event_type;
}

##  Return a list of files based on a directory
sub get_list_of_files_in_dir($) {
  my ($path_to_files,$file_prefix) = @_;
  if ($file_prefix) {print("files must be prefixed with '$file_prefix'\n");}
  my @list_of_files;

  print "Returning files from " . $path_to_files . "\n";
  opendir DIR,$path_to_files;
  my @dir = readdir(DIR);
  close DIR;
  ## loop thanks to https://stackoverflow.com/a/1045814
  foreach(@dir){
      if (-f $path_to_files . "/" . $_ ){
        if(!$file_prefix || m/^$file_prefix/) {
          # either $file_prefix is empty or filename starts with $file_prefix.  Note: a sane human would include $_ =~ in the match above but I'm playing with Perl
          push (@list_of_files, $path_to_files . "/" . $_);    # will return a list of files
        }
      }elsif(-d $path_to_files . "/" . $_){
        next if $_ =~ /^\.\.?$/;   ##  Skip . and .. https://stackoverflow.com/a/21203371
        print "ignoring directory " . $path_to_files . "/" . $_ . "\n";
      }else{
        print "ignoring non file non directory " . $path_to_files . "/" . $_ . "\n";
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
    print "https://pixabay.com/";
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
