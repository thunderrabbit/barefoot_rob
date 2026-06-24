#!/usr/bin/perl
# gen_items_feed.pl — build the badmin #4 uploader feed from the catalog sidecars.
#
# Reads the per-item catalog sidecars and writes sayonara_feed.json: the list of
# items (slug, name, category) the #4 list-driven uploader offers. badmin shows
# feed MINUS slugs already in its manifest, so an item drops off once photographed.
#
# Deploy the output to b.rn at $ITEMS_BASE_DIR/sayonara_feed.json (see README note).
#
# Env overrides:
#   SAYONARA_CATALOG  dir of *.json sidecars (default ~/barefoot_rob_master/data/sayonara/items)
#   SAYONARA_FEED     output path            (default ~/barefoot_rob_master/data/sayonara/sayonara_feed.json)

use strict;
use warnings;
use utf8;
use JSON::PP;

my $home        = $ENV{HOME};
my $catalog_dir = $ENV{SAYONARA_CATALOG} // "$home/barefoot_rob_master/data/sayonara/items";
my $feed_path   = $ENV{SAYONARA_FEED}    // "$home/barefoot_rob_master/data/sayonara/sayonara_feed.json";

sub slurp {
    my $path = shift;
    local $/;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    my $c = <$fh>;
    close $fh;
    return $c;
}

opendir(my $dh, $catalog_dir) or die "cannot open catalog dir $catalog_dir: $!";
my @files = sort grep { /\.json$/ } readdir $dh;
closedir $dh;

my @feed;
for my $f (@files) {
    my $item = decode_json(slurp("$catalog_dir/$f"));
    next unless $item->{slug};
    push @feed, {
        slug     => $item->{slug},
        name     => $item->{name} // $item->{slug},
        category => $item->{category} // "",
    };
}

@feed = sort { lc($a->{name}) cmp lc($b->{name}) } @feed;

my $json = JSON::PP->new->utf8->canonical->pretty->encode(\@feed);
open my $ofh, '>:raw', $feed_path or die "cannot write $feed_path: $!";
print $ofh $json;
close $ofh;

printf "wrote %d items to %s\n", scalar(@feed), $feed_path;
