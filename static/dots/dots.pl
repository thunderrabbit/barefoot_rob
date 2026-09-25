#!/usr/bin/perl
# dots.pl — the write side of internet DOTS. For now it only creates games.
#   POST /dots/dots.pl?do=create  ->  {"id":"<12 hex>"}
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

my ($do) = ($ENV{QUERY_STRING} // '') =~ /(?:^|&)do=([a-z]+)/;
reply('405 Method Not Allowed', '{"error":"POST only"}')
  unless ($ENV{REQUEST_METHOD} // '') eq 'POST';
reply('400 Bad Request', '{"error":"unknown do"}')
  unless defined $do && $do eq 'create';

my $games = "$BACKEND/games";
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
