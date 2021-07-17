package rpl::Functions;

use strict;
use DateTime;
use Date::Parse;

my $zone = "Asia/Tokyo";
my $zoffset = "+09:00";

our $dt = DateTime->now(
    time_zone  => $zone,
);

our $thedate = $dt->ymd;  # year-month-date (numeric).
our $thetime = $dt->hms;  # hour-min-sec    (numeric).
our $year    = $dt->year;
our $month   = $dt->month;
our $day     = $dt->day;
our $tz_date = $thedate . "T" . $thetime . $zoffset;

sub get_title($)
{
  my ($prefix) = @_;
  my $confirmed = 0;
  my $title;
  while (!$confirmed) {
    print "Enter title that comes after '" . $prefix . "'\n\n";
    $title = <STDIN>;
    $title =~ s/\s+/ /g;       # two spaces => one space
    $title =~ s/^\s+|\s+$//g;  # strip surrounding whitespace
    $title =~ s/^"(.*)"$/$1/;  # strip surrounding "s
    $title =~ s/^\s+|\s+$//g;  # strip surrounding whitespace  }
    $title = $prefix.$title;
    $confirmed = ask_confirm_string($title);
  }
  return $title;
}

sub get_date($) {
  my ($dt_now) = @_;
  my $confirmed = 0;
  my $user_dt;   # will be returned once we confirm its value
  while (!$confirmed) {
    show_dates($dt_now);
    my $user_date = input_date($dt_now);
    $user_dt = parse_user_date($user_date);
    $confirmed = ask_confirm_date($user_dt);
  }
  # return DateTime which has been parsed by `parse_user_date` and confirmed by user
  return ($user_dt);
}

sub show_dates($) {
  my ($dt_now) = @_;
  my $dt = $dt_now->clone;      # don't mess with global date
  my $desired_day_of_week = 4;  # Thursday
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
  my $string_to_confirm = $dt->strftime("%A %d %B %Y");   ##  Sunday 30 May 2021
  return ask_confirm_string($string_to_confirm);
}

sub ask_confirm_string($) {
  my ($string_to_confirm) = @_;
  my $confirmed = 0;
  print "\nIs this correct?  (yes/no)\n";
  print "  $string_to_confirm\n";
  while (1) {
    my $resp = <STDIN>;
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
  my ($dt_now) = @_;
  my $thedate = $dt->ymd;  # year-month-date (numeric).
  print "Input date of event: ($thedate)\n";
  my $user_date = <STDIN>;
  chomp($user_date);
  return length($user_date) ? $user_date : $thedate;
}

sub parse_user_date($) {
  my ($user_date) = @_;
  print "in parse got this date: $user_date \n";
  my $epoch = str2time($user_date);    #  https://stackoverflow.com/a/7487117/194309
  return DateTime->from_epoch(epoch => $epoch, time_zone  => $zone);   # https://metacpan.org/pod/DateTime#DateTime-%3Efrom_epoch(-epoch-=%3E-$epoch,-...-)
}

sub kebab_case($) {
  my ($title) = @_;
      $title = lc($title);    # make title lowercase
      $title =~ s/[\`\!\@\#\$\%\^\&\*\(\)\[\]\\\{\}\|\;\'\:\"\<\>\?\s]/-/g;
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

      my $newtagstring = <STDIN>;
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

sub get_event_type(@) {
  my (@event_types) = @_;
  my $event_type;
  my $selected_type;

    print "\n";
    print "Possible event types:\n";
    print "\n";

    my $num_event_types = scalar(@event_types);
    foreach my $ii (1..$num_event_types) {
      my $iipad = " " x (length($num_event_types) - length($ii));
      print "$iipad($ii) $event_types[$ii-1] $iipad($ii)\n";
    }# $ii

    $selected_type = "3";    ###  hardcode while testing
    print "Enter the number of the type you want to select: ($selected_type) ";
    my $raw_input = <STDIN>;

    $raw_input =~ s/\D+//g;     ## TODO: how to specify this ain't raw anymore?
    chomp($raw_input);
    $selected_type = length($raw_input) ? $raw_input : $selected_type;
    $event_type = $event_types[$selected_type-1];

    # confirm selected image
    print "\nCtrl-C if you ain't happy with your choice!\n";
    print "  event_type:     $event_type\n";

  return $event_type;
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
    my $jj = <STDIN>;

    $episode_image = $episode_images[$jj-1];
    $episode_thumb = $episode_thumbs[$jj-1];

    # confirm selected image
    $confirmed = ask_confirm_string($episode_image);

  }# !$confirmed

  return ($episode_image,$episode_thumb);

}# get_episode_image()
