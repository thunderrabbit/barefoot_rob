#!/usr/bin/perl
# dots.pl — internet DOTS. For now it creates games, reads them back, and
# appends moves. No players or turns yet: anyone with the id may move.
#   POST /dots/dots.pl?do=create                 ->  {"id":"<12 hex>"}
#   GET  /dots/dots.pl?id=<id>                   ->  the game's JSON
#   POST /dots/dots.pl?do=move&id=<id>&edge=h,1,2 ->  {"n":<move count>}
# Game files live outside the web root, so nothing here is served directly.
use strict;
use warnings;
use Fcntl qw(:flock);
use JSON::PP;

my $BACKEND = $ENV{DOTS_BACKEND}
  || '/home/barefoot_rob/dots_backend_since_2026_sep_25_tranmere';

sub reply {
    my ($status, $json) = @_;
    # DreamHost adds a two-day max-age to JSON; games change every move.
    # mod_expires leaves alone a response that already carries Expires.
    print "Status: $status\nContent-Type: application/json\n"
        . "Cache-Control: no-store\nExpires: Thu, 01 Jan 1970 00:00:00 GMT\n\n$json\n";
    exit;
}

my $games = "$BACKEND/games";
my $query = $ENV{QUERY_STRING} // '';
my $method = $ENV{REQUEST_METHOD} // '';

sub param {
    my ($name) = @_;
    my ($value) = $query =~ /(?:^|&)\Q$name\E=([^&]*)/;
    $value =~ s/%2C/,/gi if defined $value;
    return $value;
}

# The id becomes a filename, so it must be exactly 12 hex digits first.
sub game_id {
    my $id = param('id');
    reply('400 Bad Request', '{"error":"bad id"}')
      unless defined $id && $id =~ /\A[a-f0-9]{12}\z/;
    return $id;
}

sub read_game {
    my ($id) = @_;
    open my $in, '<', "$games/$id.json" or reply('404 Not Found', '{"error":"no such game"}');
    my $json = do { local $/; <$in> };
    chomp $json;
    return $json;
}

# Write beside the target, then rename: a reader never sees half a file.
sub write_game {
    my ($id, $json) = @_;
    my $tmp = "$games/.$id.tmp";
    open my $fh, '>', $tmp or reply('500 Internal Server Error', '{"error":"cannot write"}');
    print $fh "$json\n";
    close $fh or reply('500 Internal Server Error', '{"error":"cannot write"}');
    rename $tmp, "$games/$id.json" or reply('500 Internal Server Error', '{"error":"cannot write"}');
}

reply('200 OK', read_game(game_id())) if $method eq 'GET';

my $do = param('do') // '';
reply('405 Method Not Allowed', '{"error":"GET or POST only"}')
  unless $method eq 'POST';

mkdir $games unless -d $games;

if ($do eq 'move') {
    my $id = game_id();
    # One writer at a time, so two moves at once cannot overwrite each other.
    open my $lock, '>>', "$games/.lock" or reply('500 Internal Server Error', '{"error":"no lock"}');
    flock $lock, LOCK_EX or reply('500 Internal Server Error', '{"error":"no lock"}');
    my $game = decode_json(read_game($id));

    # Canonical keys from game.js: 'h,x,y' is the line under box (x,y),
    # 'v,x,y' the line left of it. No leading zeros, so each edge has one name.
    my $edge = param('edge') // '';
    my ($hv, $x, $y) = $edge =~ /\A([hv]),([1-9][0-9]?),([1-9][0-9]?)\z/;
    reply('400 Bad Request', '{"error":"bad edge"}')
      unless defined $hv
      && $x <= $game->{w} + ($hv eq 'v' ? 1 : 0)
      && $y <= $game->{h} + ($hv eq 'h' ? 1 : 0);
    reply('409 Conflict', '{"error":"there is already a line there"}')
      if grep { $_ eq $edge } @{ $game->{moves} };

    push @{ $game->{moves} }, $edge;
    write_game($id, JSON::PP->new->canonical->encode($game));
    reply('200 OK', '{"n":' . scalar(@{ $game->{moves} }) . '}');
}

reply('400 Bad Request', '{"error":"unknown do"}') unless $do eq 'create';

open my $rand, '<:raw', '/dev/urandom' or reply('500 Internal Server Error', '{"error":"no random"}');
read $rand, my $bytes, 6;
close $rand;
my $id = unpack 'H*', $bytes;
write_game($id, '{"h":5,"moves":[],"w":5}');

reply('200 OK', qq({"id":"$id"}));
