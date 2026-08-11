#!/usr/bin/env perl
use strict;
use warnings;

## Create a Zoom meeting with registration enabled for each event generator
## given, and report the registration URL that belongs on the website.
##
##   ./zoom_schedule.pl --dry-run event_generators/2026/2026_08_19_ring_ring.txt
##   ./zoom_schedule.pl          event_generators/2026/2026_08_*_ring_ring.txt
##
## The generator file is the single source of truth for date, time, duration
## and title -- the same file generate_events.pl replays to build the page --
## so the Zoom meeting and the web page cannot drift apart.
##
## There is no circularity: Zoom needs the date, time and title, and the
## generator needs the registration URL on line 6, which only exists after the
## meeting is made.  So write the generator with line 6 blank, run this, and it
## fills line 6 in for you.  Then run generate_events.pl.
##
## A filled line 6 also means "this meeting exists", so re-running skips it.
## Nothing else is written down: the registration URL is the only thing we need
## afterwards, and the host reaches the meeting through his own Zoom account.
##
## Credentials come from a Server-to-Server OAuth app and live OUTSIDE this
## repo, at ~/.config/zoom/robnugen_s2s.env by default (override with
## $ZOOM_CREDS).  Never paste them into a file in here.

use Cwd qw( abs_path );
use File::Basename qw( dirname );
use lib dirname(abs_path(__FILE__));
use rpl::Constants;

use JSON::PP;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST PATCH);
use MIME::Base64 qw(encode_base64);
use DateTime;
use Encode qw(encode_utf8);

my $dry_run     = 0;
my $ask_phone   = 0;
my $update_zoom = 0;
my @generator_files;
for my $arg (@ARGV) {
  if    ($arg eq "--dry-run")     { $dry_run     = 1 }
  elsif ($arg eq "--ask-phone")   { $ask_phone   = 1 }
  elsif ($arg eq "--update-zoom") { $update_zoom = 1 }
  else                            { push @generator_files, $arg }
}
@generator_files
  or die "usage: $0 [--dry-run] [--ask-phone] <generator.txt> [...]\n"
       . "       $0 --update-zoom [--dry-run] <generator.txt> [...]\n";

my $json = JSON::PP->new->utf8->canonical->pretty;

## What registrants see as the meeting description, read from the file that sits
## beside the page template -- see %event_zoom_agenda_files in Constants.pm for
## why it lives there rather than here.
##
## Every failure is fatal.  A blank agenda is not a small cosmetic problem: it
## goes out on a live registration page and in the confirmation email, and the
## only way to notice is to look.  Zoom's own limit is 2000 characters, and it
## truncates silently rather than complaining, so check that here too.
my $ZOOM_AGENDA_MAX = 2000;

sub agenda_for {
  my ($event_type) = @_;
  my $path = $rpl::Constants::event_zoom_agenda_files{$event_type}
    or die "no Constants::event_zoom_agenda_files{$event_type} -- add one "
         . "before scheduling a '$event_type' meeting\n";

  open my $fh, "<:encoding(UTF-8)", $path
    or die "cannot read the Zoom agenda at $path: $!\n"
         . "This file is deliberately untracked, so a fresh clone will not have "
         . "it.  Write it before scheduling, or Zoom gets a blank description.\n";
  my $agenda = do { local $/; <$fh> };
  close $fh;

  $agenda =~ s/\s+\z//;
  length $agenda
    or die "the Zoom agenda at $path is empty\n";
  length($agenda) <= $ZOOM_AGENDA_MAX
    or die "the Zoom agenda at $path is " . length($agenda) . " characters; "
         . "Zoom allows $ZOOM_AGENDA_MAX and truncates the rest without saying so\n";

  return $agenda;
}

## ------------------------------------------------------------- generator file

## Answers are positional, in the order generate_events.pl prompts for them
## (see generate_events.pl:88-115).  A blank answer accepted the default, so a
## blank here means "whatever Constants.pm says".
##
## Positional parsing is brittle by nature: if the prompt order ever changes,
## a silent misread would schedule the wrong thing.  So every field is checked,
## and anything unexpected is fatal rather than quietly wrong.
sub read_generator {
  my ($path) = @_;
  open my $fh, "<", $path or die "cannot read $path: $!\n";
  my @answer = <$fh>;
  close $fh;
  chomp @answer;

  my $event_type = $answer[0] // "";
  my $date       = $answer[1] // "";
  my $time       = $answer[2] // "";
  my $duration   = $answer[4] // "";

  ## Line 8 is a title SUFFIX, not a title: Functions::get_title prompts with
  ## "Enter title that comes after '<prefix>'" and returns prefix + answer.
  ## Reading it as the whole title drops the prefix, which is how the afternoon
  ## session came to be called " (afternoon session)" on Zoom while its page
  ## says "Ring Ring! ... Are You Willing to Answer? (afternoon session)".
  my $suffix     = $answer[7] // "";

  die "$path: only " . scalar(@answer) . " answers; this does not look like a "
    . "complete event generator\n"
    unless @answer >= 8;
  die "$path: line 1 '$event_type' is not a known event type\n"
    unless exists $rpl::Constants::event_template_files{$event_type};
  die "$path: line 2 '$date' is not a YYYY-MM-DD date\n"
    unless $date =~ /^\d{4}-\d{2}-\d{2}$/;
  die "$path: line 3 '$time' is not an HH:MM time\n"
    unless $time =~ /^\d{2}:\d{2}$/;
  die "$path: line 5 '$duration' is not a number of minutes\n"
    if length($duration) && $duration !~ /^\d+$/;

  $duration ||= $rpl::Constants::event_duration_minutes{$event_type}
    or die "$path: no duration on line 5 and no "
         . "Constants::event_duration_minutes{$event_type}\n";
  my $prefix = $rpl::Constants::event_title_prefixes{$event_type} // "";
  $suffix =~ s/\s+/ /g;
  $suffix =~ s/^\s+|\s+$//g;
  my $title = length $suffix ? "$prefix $suffix" : $prefix;
  $title =~ s/^\s+|\s+$//g;

  die "$path: no title on line 8 and no "
     . "Constants::event_title_prefixes{$event_type}\n"
    unless length $title;

  return {
    path         => $path,
    lines        => \@answer,
    event_type   => $event_type,
    title        => $title,
    duration     => $duration,
    start        => "${date}T${time}:00",
    location_url => $answer[5] // "",
  };
}

## Put the registration URL where generate_events.pl will read it, and where
## `git diff` will show it.  Line 6 is the "event location URL" answer.
sub write_location_url {
  my ($session, $url) = @_;
  my @lines = @{ $session->{lines} };
  $lines[5] = $url;
  open my $fh, ">", $session->{path}
    or die "created the meeting but cannot write $session->{path}: $!\n"
         . "registration URL was: $url\n";
  print $fh join("\n", @lines), "\n";
  close $fh;
}

## ---------------------------------------------------------------- credentials

sub read_credentials {
  my $path = $ENV{ZOOM_CREDS} || "$ENV{HOME}/.config/zoom/robnugen_s2s.env";
  open my $fh, "<", $path or die "cannot read credentials at $path: $!\n";
  my %cred;
  while (my $line = <$fh>) {
    next if $line =~ /^\s*(#|$)/;
    next unless $line =~ /^\s*(\w+)\s*=\s*(.*?)\s*$/;
    $cred{$1} = $2;
  }
  close $fh;
  for my $key (qw(ZOOM_ACCOUNT_ID ZOOM_CLIENT_ID ZOOM_CLIENT_SECRET)) {
    die "$key is empty in $path\n" unless $cred{$key};
  }
  return \%cred;
}

sub access_token {
  my ($cred, $ua) = @_;
  my $basic = encode_base64("$cred->{ZOOM_CLIENT_ID}:$cred->{ZOOM_CLIENT_SECRET}", "");
  my $res = $ua->request(POST
    "https://zoom.us/oauth/token"
      . "?grant_type=account_credentials&account_id=$cred->{ZOOM_ACCOUNT_ID}",
    Authorization => "Basic $basic",
  );
  die "token request failed: " . $res->status_line . "\n" . $res->decoded_content . "\n"
    unless $res->is_success;
  my $body = decode_json($res->decoded_content);
  die "no access_token in token response\n" unless $body->{access_token};
  return $body->{access_token};
}

## ------------------------------------------------------------------- payloads

## Zoom reads registration off approval_type: 0 means "registration required,
## automatically approve", which is what we want -- anything else makes Rob
## approve each person by hand before they receive a join link.
sub meeting_payload {
  my ($session) = @_;
  return {
    topic      => $session->{title},
    type       => 2,                       # scheduled, one-off
    start_time => $session->{start},       # local time; timezone below
    duration   => $session->{duration},
    timezone   => "Asia/Tokyo",
    agenda     => agenda_for($session->{event_type}),
    settings   => {
      approval_type                  => 0,
      registrants_confirmation_email => JSON::PP::true,  # carries the join link
      registrants_email_notification => JSON::PP::true,
      auto_recording                 => "none",          # Rob starts and stops by hand
      host_video                     => JSON::PP::true,
      participant_video              => JSON::PP::false,
      audio                          => "both",
    },
  };
}

## First Name and Email are always collected, and that is all we ask for by
## default -- there is nowhere to put a phone number, and every extra field on
## a free event costs signups.  --ask-phone adds one, still optional.
sub questions_payload {
  return {
    custom_questions => [
      { title => "Phone number (optional)", type => "short", required => JSON::PP::false },
    ],
  };
}

## -------------------------------------------------------------- finding again

## The meeting id is never written down -- only the registration URL is, on line
## 6 -- so an update has to go looking.  Zoom's List Meetings response does not
## carry registration_url, so this narrows on start time first (cheap, and
## normally leaves one candidate) and then confirms on registration_url, which
## is the only field that ties a meeting to a generator beyond doubt.
##
## Topic is deliberately NOT used for matching: it is the field most likely to
## have been edited in the Zoom UI, and it is already wrong on at least one
## meeting -- see the note about title suffixes in read_generator.

sub get_json {
  my ($ua, $token, $url) = @_;
  my $res = $ua->get($url, Authorization => "Bearer $token");
  die "GET $url failed: " . $res->status_line . "\n" . $res->decoded_content . "\n"
    unless $res->is_success;
  return decode_json($res->decoded_content);
}

## Zoom stores the meeting in Asia/Tokyo but lists it back in UTC.
sub utc_start {
  my ($session) = @_;
  my ($y, $mo, $d, $h, $mi, $s) = $session->{start}
    =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})$/
    or die "cannot parse start time '$session->{start}'\n";
  my $dt = DateTime->new(
    year => $y, month => $mo, day => $d,
    hour => $h, minute => $mi, second => $s,
    time_zone => "Asia/Tokyo",
  );
  $dt->set_time_zone("UTC");
  return $dt->strftime("%Y-%m-%dT%H:%M:%SZ");
}

sub scheduled_meetings {
  my ($ua, $token) = @_;
  my @meetings;
  my $next = "";
  while (1) {
    my $url = "https://api.zoom.us/v2/users/me/meetings"
            . "?type=scheduled&page_size=300";
    $url .= "&next_page_token=$next" if length $next;
    my $page = get_json($ua, $token, $url);
    push @meetings, @{ $page->{meetings} || [] };
    $next = $page->{next_page_token} // "";
    last unless length $next;
  }
  return @meetings;
}

sub find_meeting {
  my ($ua, $token, $session, $all) = @_;
  my $want_start = utc_start($session);
  my $want_url   = $session->{location_url};

  my @at_that_time = grep { ($_->{start_time} // "") eq $want_start } @$all;
  @at_that_time
    or die "$session->{path}: no scheduled meeting starts at $want_start "
         . "($session->{start} Asia/Tokyo).\nIt may have already happened -- "
         . "Zoom lists past meetings separately.\n";

  my @matched;
  for my $meeting (@at_that_time) {
    my $detail = get_json($ua, $token,
      "https://api.zoom.us/v2/meetings/$meeting->{id}");
    push @matched, $detail
      if ($detail->{registration_url} // "") eq $want_url;
  }

  @matched == 1
    or die "$session->{path}: " . scalar(@matched) . " of the "
         . scalar(@at_that_time) . " meetings at $want_start have registration "
         . "URL\n  $want_url\nExpected exactly one.\n";

  return $matched[0];
}

## ----------------------------------------------------------------------- main

my @sessions = map { read_generator($_) } @generator_files;

## Everything that can be known without asking Zoom is checked before asking
## Zoom, so a typo costs a second rather than a half-finished run across three
## meetings.  agenda_for is called for the die, and its result thrown away.
if ($update_zoom) {
  for my $session (@sessions) {
    length $session->{location_url}
      or die "$session->{path}: line 6 is blank, so no meeting was ever made "
           . "from this generator and there is nothing to update.\n";
    agenda_for($session->{event_type});
  }
}

## A creation dry run needs no credentials -- it only prints what it would send.
## An update dry run does need them: saying what would change means reading what
## is there now.
if ($dry_run && !$update_zoom) {
  print "DRY RUN -- nothing will be created\n\n";
  for my $session (@sessions) {
    print "$session->{path}\n";
    print "POST https://api.zoom.us/v2/users/me/meetings\n";
    print $json->encode(meeting_payload($session));
    if ($ask_phone) {
      print "PATCH https://api.zoom.us/v2/meetings/{id}/registrants/questions\n";
      print $json->encode(questions_payload());
    }
    print "\n";
  }
  exit 0;
}

my $ua    = LWP::UserAgent->new(timeout => 30);
my $cred  = read_credentials();
my $token = access_token($cred, $ua);

## ------------------------------------------------------- update existing only

## The two fields that are words, and are supposed to say what the website says:
## topic and agenda.  Date, time and duration are deliberately NOT touched --
## moving those under someone who has already registered is a different kind of
## mistake from a stale sentence, and Zoom emails registrants about it.
##
## Only what actually differs is sent, so a re-run is a no-op and says so.
if ($update_zoom) {
  print "DRY RUN -- nothing will be changed\n\n" if $dry_run;

  my @all = scheduled_meetings($ua, $token);
  my $changed = 0;

  for my $session (@sessions) {
    my $meeting = find_meeting($ua, $token, $session, \@all);

    printf "%s\n  meeting %s  %s\n", $session->{path}, $meeting->{id},
      $session->{start};

    my %want = (
      topic  => $session->{title},
      agenda => agenda_for($session->{event_type}),
    );

    my %change;
    for my $field (sort keys %want) {
      my $old = $meeting->{$field} // "";
      next if $old eq $want{$field};
      $change{$field} = $want{$field};
      print encode_utf8("  $field\n    - $old\n    + $want{$field}\n");
    }

    unless (%change) {
      print "  already current\n\n";
      next;
    }

    print "\n";
    next if $dry_run;

    my $res = $ua->request(PATCH
      "https://api.zoom.us/v2/meetings/$meeting->{id}",
      Authorization  => "Bearer $token",
      "Content-Type" => "application/json",
      Content        => encode_json(\%change),
    );
    die "updating " . join(" and ", sort keys %change)
      . " on meeting $meeting->{id} failed: "
      . $res->status_line . "\n" . $res->decoded_content . "\n"
      unless $res->is_success;
    print "  updated " . join(" and ", sort keys %change) . "\n\n";
    $changed++;
  }

  print $dry_run ? "nothing sent\n" : "$changed meeting(s) updated\n";
  exit 0;
}

my @created;
for my $session (@sessions) {

  ## Creating the same meeting twice is the one mistake this script could make
  ## that Rob would have to clean up by hand in the Zoom UI, so a generator
  ## that already carries a URL is left alone.  Blank line 6 to make another.
  if (length $session->{location_url}) {
    print "skipping $session->{path} -- line 6 already filled\n";
    next;
  }

  my $res = $ua->request(POST "https://api.zoom.us/v2/users/me/meetings",
    Authorization  => "Bearer $token",
    "Content-Type" => "application/json",
    Content        => encode_json(meeting_payload($session)),
  );
  die "creating '$session->{title}' ($session->{start}) failed: "
    . $res->status_line . "\n" . $res->decoded_content . "\n"
    unless $res->is_success;

  my $meeting = decode_json($res->decoded_content);
  printf "created %s  %s  %s\n", $meeting->{id}, $session->{start}, $session->{path};

  ## The phone question is a nice-to-have.  If the app is short a scope for it,
  ## say so and keep the meeting -- Zoom names the scope it wanted.
  if ($ask_phone) {
    my $qres = $ua->request(PATCH
      "https://api.zoom.us/v2/meetings/$meeting->{id}/registrants/questions",
      Authorization  => "Bearer $token",
      "Content-Type" => "application/json",
      Content        => encode_json(questions_payload()),
    );
    if ($qres->is_success) {
      print "        phone question added\n";
    } else {
      print "        phone question NOT added: " . $qres->status_line . "\n";
      print "        " . $qres->decoded_content . "\n";
    }
  }

  my $registration_url = $meeting->{registration_url}
    or die "meeting $meeting->{id} was created but Zoom returned no "
         . "registration_url -- check that registration is enabled on it\n";

  write_location_url($session, $registration_url);
  push @created, { generator => $session->{path}, url => $registration_url };
}

exit 0 unless @created;

print "\nregistration URLs, now on line 6 of each generator:\n";
for my $entry (@created) {
  printf "  %s\n      %s\n", $entry->{generator}, $entry->{url};
}
print "\nnext: ./generate_events.pl < each generator, then ./check_links.pl\n";
