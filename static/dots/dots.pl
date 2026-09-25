#!/usr/bin/perl
# dots.pl — internet DOTS. For now it creates games and reads them back.
#   POST /dots/dots.pl?do=create  ->  {"id":"<12 hex>"}
#   GET  /dots/dots.pl?id=<id>    ->  the game's JSON
# Game files live outside the web root, so nothing here is served directly.
use strict;
use warnings;

my $BACKEND = $ENV{DOTS_BACKEND}
  || '/home/barefoot_rob/dots_backend_since_2026_sep_25_tranmere';

sub reply {
    my ($status, $json) = @_;
    print "Status: $status\nContent-Type: application/json\n\n$json\n";
    exit;
}

my $games = "$BACKEND/games";
my $query = $ENV{QUERY_STRING} // '';
my $method = $ENV{REQUEST_METHOD} // '';

if ($method eq 'GET') {
    my ($id) = $query =~ /(?:^|&)id=([^&]*)/;
    # The id becomes a filename, so it must be exactly 12 hex digits first.
    reply('400 Bad Request', '{"error":"bad id"}')
      unless defined $id && $id =~ /\A[a-f0-9]{12}\z/;
    open my $in, '<', "$games/$id.json" or reply('404 Not Found', '{"error":"no such game"}');
    local $/;
    my $json = <$in>;
    chomp $json;
    reply('200 OK', $json);
}

my ($do) = $query =~ /(?:^|&)do=([a-z]+)/;
reply('405 Method Not Allowed', '{"error":"GET or POST only"}')
  unless $method eq 'POST';
reply('400 Bad Request', '{"error":"unknown do"}')
  unless defined $do && $do eq 'create';

mkdir $games unless -d $games;

open my $rand, '<:raw', '/dev/urandom' or reply('500 Internal Server Error', '{"error":"no random"}');
read $rand, my $bytes, 6;
close $rand;
my $id = unpack 'H*', $bytes;

# Write beside the target, then rename: a reader never sees half a file.
my $tmp = "$games/.$id.tmp";
open my $fh, '>', $tmp or reply('500 Internal Server Error', '{"error":"cannot write"}');
print $fh qq({"w":5,"h":5,"moves":[]}\n);
close $fh or reply('500 Internal Server Error', '{"error":"cannot write"}');
rename $tmp, "$games/$id.json" or reply('500 Internal Server Error', '{"error":"cannot write"}');

reply('200 OK', qq({"id":"$id"}));
