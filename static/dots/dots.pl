#!/usr/bin/perl
# dots.pl — internet DOTS. For now it creates and joins games, reads them
# back, and appends moves. Each seat has a secret token; a move needs one,
# but there are no turns yet: either player may move at any time.
#   POST do=create                           ->  {"id":"<12 hex>","token":"<32 hex>"}
#   POST do=join&id=<id>                     ->  {"token":"<32 hex>"}
#   GET  id=<id>                             ->  the game's JSON
#   POST do=move&id=<id>&token=<t>&edge=h,1,2 ->  {"n":<move count>}
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
sub write_file {
    my ($name, $content) = @_;
    my $tmp = "$games/.$name.tmp";
    open my $fh, '>', $tmp or reply('500 Internal Server Error', '{"error":"cannot write"}');
    print $fh $content;
    close $fh or reply('500 Internal Server Error', '{"error":"cannot write"}');
    rename $tmp, "$games/$name" or reply('500 Internal Server Error', '{"error":"cannot write"}');
}

sub write_game { my ($id, $json) = @_; write_file("$id.json", "$json\n") }

# Seat tokens sit in their own file, one per line in seat order, so the
# game JSON that GET hands out never contains them.
sub read_tokens {
    my ($id) = @_;
    open my $in, '<', "$games/$id.tok" or return ();
    chomp(my @tokens = <$in>);
    return @tokens;
}

sub write_tokens { my ($id, @tokens) = @_; write_file("$id.tok", join('', map {"$_\n"} @tokens)) }

sub random_hex {
    my ($bytes) = @_;
    open my $rand, '<:raw', '/dev/urandom' or reply('500 Internal Server Error', '{"error":"no random"}');
    my $buf = q();
    read($rand, $buf, $bytes) == $bytes or reply('500 Internal Server Error', '{"error":"no random"}');
    return unpack 'H*', $buf;
}

# One writer at a time, so two requests at once cannot overwrite each other.
# The lock is released when the returned handle goes away at exit.
sub lock_games {
    open my $lock, '>>', "$games/.lock" or reply('500 Internal Server Error', '{"error":"no lock"}');
    flock $lock, LOCK_EX or reply('500 Internal Server Error', '{"error":"no lock"}');
    return $lock;
}

reply('200 OK', read_game(game_id())) if $method eq 'GET';

my $do = param('do') // '';
reply('405 Method Not Allowed', '{"error":"GET or POST only"}')
  unless $method eq 'POST';

mkdir $games unless -d $games;

if ($do eq 'join') {
    my $id = game_id();
    my $lock = lock_games();
    read_game($id);                           # 404 if there is no such game
    my @tokens = read_tokens($id);
    reply('409 Conflict', '{"error":"someone already joined"}') if @tokens != 1;
    my $token = random_hex(16);
    write_tokens($id, @tokens, $token);
    reply('200 OK', qq({"token":"$token"}));
}

if ($do eq 'move') {
    my $id = game_id();
    my $lock = lock_games();
    my $game = decode_json(read_game($id));
    my $token = param('token') // '';
    reply('403 Forbidden', '{"error":"not your game"}')
      unless length $token && grep { $_ eq $token } read_tokens($id);

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

my $id = random_hex(6);
my $token = random_hex(16);
write_tokens($id, $token);                    # tokens first: no game without seats
write_game($id, '{"h":5,"moves":[],"w":5}');

reply('200 OK', qq({"id":"$id","token":"$token"}));
