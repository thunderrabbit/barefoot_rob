#!/usr/bin/perl
# dots.pl — internet DOTS. It creates and joins games, reads them back, and
# appends moves. Each seat has a secret token, and a move needs the token of
# the seat whose turn it is. Player one (seat 0) moves first.
#   POST do=create[&w=5&h=5][&name=One][&color=12][&listed=1] ->  {"id":"<12 hex>","token":"<32 hex>"}
#   POST do=join&id=<id>[&name=Two][&color=9]        ->  {"token":"<32 hex>"}
#   GET  id=<id>                             ->  the game's JSON
#   GET  do=list                             ->  {"waiting":[…],"playing":[…],"done":[…]}
#   POST do=move&id=<id>&token=<t>&edge=h,1,2 ->  {"n":<move count>,"turn":0|1}
# Game files live outside the web root, so nothing here is served directly.
use strict;
use warnings;
use Fcntl qw(:flock);
use JSON::PP;
use Encode qw(decode);

# Game files are UTF-8 bytes; names may be any language.
my $JSON = JSON::PP->new->utf8->canonical;

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
    return undef unless defined $value;
    $value =~ tr/+/ /;
    $value =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
    return decode('UTF-8', $value);     # bad bytes become U+FFFD, never die
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

# Count one more side on each box this edge borders ('h,x,y' lies between
# boxes (x,y-1) and (x,y); 'v,x,y' between (x-1,y) and (x,y)). Returns true
# when it finishes a box, which in DOTS means the same player goes again.
sub add_edge {
    my ($sides, $edge, $w, $h) = @_;
    my ($hv, $x, $y) = split /,/, $edge;
    my $boxed = 0;
    for my $box ($hv eq 'h' ? ([$x, $y - 1], [$x, $y]) : ([$x - 1, $y], [$x, $y])) {
        my ($bx, $by) = @$box;
        next if $bx < 1 || $bx > $w || $by < 1 || $by > $h;
        $boxed = 1 if ++$sides->{"$bx,$by"} == 4;
    }
    return $boxed;
}

# Whose turn it is after every move so far, by replaying them from the start.
sub turn_after {
    my ($game) = @_;
    my (%sides, $turn);
    $turn = 0;
    for my $edge (@{ $game->{moves} }) {
        $turn = 1 - $turn unless add_edge(\%sides, $edge, $game->{w}, $game->{h});
    }
    return $turn;
}

# A player as the game file stores it. The name is shown with textContent in
# the browser, but still: no control or invisible formatting characters, and
# the same 15-character limit the setup screen's name box has.
sub player {
    my ($default_name, $default_color) = @_;
    my $name = param('name') // $default_name;
    $name =~ s/[\p{Cc}\p{Cf}]//g;
    $name =~ s/\s+/ /g;
    $name =~ s/\A | \z//g;
    reply('400 Bad Request', '{"error":"name must be 1 to 15 characters"}')
      unless length $name && length $name <= 15;
    # EGA colours 1..15; 0 is black, the board itself.
    my $color = param('color') // $default_color;
    reply('400 Bad Request', '{"error":"color must be 1 to 15"}')
      unless $color =~ /\A[1-9][0-9]?\z/ && $color <= 15;
    return { name => $name, color => 0 + $color };
}

# The lobby: listed games, newest first, in three groups. Each entry is a
# summary, so the lobby never needs every move of every game.
sub lobby {
    my %cap = (waiting => 20, playing => 20, done => 10);
    my %group = map { $_ => [] } keys %cap;
    opendir my $dir, $games or return $JSON->encode(\%group);
    my @found;
    for my $file (readdir $dir) {
        my ($id) = $file =~ /\A([a-f0-9]{12})\.json\z/ or next;
        my $mtime = (stat "$games/$file")[9] or next;
        push @found, [$id, $mtime];
    }
    for my $f (sort { $b->[1] <=> $a->[1] } @found) {
        my ($id, $mtime) = @$f;
        open my $in, '<', "$games/$id.json" or next;
        my $game = eval { $JSON->decode(do { local $/; <$in> }) } or next;
        next if defined $game->{listed} && !$game->{listed};  # older games are listed
        my $edges = $game->{w} * ($game->{h} + 1) + ($game->{w} + 1) * $game->{h};
        my $moves = @{ $game->{moves} };
        my $kind = @{ $game->{players} || [] } < 2 ? 'waiting'
                 : $moves >= $edges                ? 'done'
                 :                                   'playing';
        next if @{ $group{$kind} } >= $cap{$kind};
        push @{ $group{$kind} }, { id => $id, w => $game->{w}, h => $game->{h},
            players => $game->{players} || [], moves => $moves, updated => $mtime };
    }
    return $JSON->encode(\%group);
}

if ($method eq 'GET') {
    reply('200 OK', lobby()) if (param('do') // '') eq 'list';
    reply('200 OK', read_game(game_id()));
}

my $do = param('do') // '';
reply('405 Method Not Allowed', '{"error":"GET or POST only"}')
  unless $method eq 'POST';

mkdir $games unless -d $games;

if ($do eq 'join') {
    my $id = game_id();
    my $lock = lock_games();
    my $game = $JSON->decode(read_game($id));   # 404 if there is no such game
    my @tokens = read_tokens($id);
    reply('409 Conflict', '{"error":"someone already joined"}') if @tokens != 1;
    # The join screen never offers player one's colour; this is the backstop.
    my $me = player('Two', 9);
    reply('400 Bad Request', '{"error":"Be original."}')
      if $me->{color} == ($game->{players}[0]{color} // 0);
    my $token = random_hex(16);
    write_tokens($id, @tokens, $token);
    push @{ $game->{players} }, $me;
    write_game($id, $JSON->encode($game));
    reply('200 OK', qq({"token":"$token"}));
}

if ($do eq 'move') {
    my $id = game_id();
    my $lock = lock_games();
    my $game = $JSON->decode(read_game($id));
    my $token = param('token') // '';
    my @tokens = read_tokens($id);
    my ($seat) = grep { $tokens[$_] eq $token } 0 .. $#tokens;
    reply('403 Forbidden', '{"error":"not your game"}')
      unless length $token && defined $seat;
    reply('409 Conflict', '{"error":"waiting for someone to join"}') if @tokens < 2;
    reply('403 Forbidden', '{"error":"not your turn"}') if $seat != turn_after($game);

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
    write_game($id, $JSON->encode($game));
    reply('200 OK', '{"n":' . scalar(@{ $game->{moves} }) . ',"turn":' . turn_after($game) . '}');
}

reply('400 Bad Request', '{"error":"unknown do"}') unless $do eq 'create';

# Board size in boxes; 1..30 is the limit the setup screen already enforces.
my %size;
for my $dim ('w', 'h') {
    my $n = param($dim) // 5;
    reply('400 Bad Request', qq({"error":"$dim must be 1 to 30"}))
      unless $n =~ /\A[1-9][0-9]?\z/ && $n <= 30;
    $size{$dim} = 0 + $n;
}

my $me = player('One', 12);
# Listed games show in the lobby; unlisted ones only reach people sent the link.
my $listed = param('listed') // 1;
reply('400 Bad Request', '{"error":"listed must be 0 or 1"}') unless $listed =~ /\A[01]\z/;
my $id = random_hex(6);
my $token = random_hex(16);
write_tokens($id, $token);                    # tokens first: no game without seats
write_game($id, $JSON->encode({ %size, listed => 0 + $listed, moves => [], players => [$me] }));

reply('200 OK', qq({"id":"$id","token":"$token"}));
