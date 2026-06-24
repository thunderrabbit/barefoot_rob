#!/usr/bin/perl
# link_sayonara_images.pl — join badmin-uploaded photos onto the catalog sidecars.
#
# badmin (the #4 uploader, or /ai/) files each photo on b.robnugen.com and appends a
# line to items_manifest.jsonl keyed by the item slug. This script pulls that manifest
# from b.rn, matches each line's slug to a catalog sidecar, and writes the public image
# URL(s) into the sidecar (images[] = the _1000 versions, in upload order; thumb = the
# first photo's thumbnail). Then re-run generate_sayonara.pl to show the photos.
#
# Runs on Lemur 13 (where the sidecars live). Only the small text manifest crosses the
# wire — never image bytes. Idempotent: re-running rewrites the same URLs.
#
# Env overrides:
#   SAYONARA_CATALOG          sidecar dir            (default ~/barefoot_rob_master/data/sayonara/items)
#   SAYONARA_MANIFEST         local manifest path; if set + present, used as-is (no scp)
#   SAYONARA_MANIFEST_REMOTE  scp source             (default b.rn:b.robnugen.com/home/tokyo/2026/p1/items/items_manifest.jsonl)
#   SAYONARA_ITEMS_URL_BASE   public URL base        (default https://b.robnugen.com/home/tokyo/2026/p1/items)

use strict;
use warnings;
use utf8;
use JSON::PP;
use File::Basename qw(fileparse);

my $home        = $ENV{HOME};
my $catalog_dir = $ENV{SAYONARA_CATALOG} // "$home/barefoot_rob_master/data/sayonara/items";
my $url_base    = $ENV{SAYONARA_ITEMS_URL_BASE} // "https://b.robnugen.com/home/tokyo/2026/p1/items";
my $remote      = $ENV{SAYONARA_MANIFEST_REMOTE}
              // "b.rn:b.robnugen.com/home/tokyo/2026/p1/items/items_manifest.jsonl";
$url_base =~ s{/+$}{};

sub slurp_raw {
    my $path = shift;
    local $/;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    my $c = <$fh>;
    close $fh;
    return $c;
}

# --- obtain the manifest -----------------------------------------------------
my $manifest;
if ($ENV{SAYONARA_MANIFEST} && -f $ENV{SAYONARA_MANIFEST}) {
    $manifest = $ENV{SAYONARA_MANIFEST};
} else {
    $manifest = "$catalog_dir/../items_manifest.jsonl";   # local cache next to the catalog
    print "pulling manifest: $remote\n";
    my $rc = system('scp', '-q', $remote, $manifest);
    die "scp of manifest failed (rc=$rc) — set SAYONARA_MANIFEST to a local copy to skip the pull\n"
        if $rc != 0;
}
die "manifest not found: $manifest\n" unless -f $manifest;

# --- map a manifest 'file' (relative to items root) to its public URLs --------
# file e.g. "book/2026-jun-24-im-fine.jpg"  or  "book/im_fine/2026-jun-24-im-fine-front.jpg"
sub urls_for {
    my $rel = shift;
    my ($name, $dir, $ext) = fileparse($rel, qr/\.[^.]*$/);   # $dir keeps trailing slash, "" if none
    $ext =~ s/^\.//;
    my $full  = "$url_base/$rel";
    my $img1k = "$url_base/${dir}${name}_1000.$ext";
    my $thumb = "$url_base/${dir}thumbs/$name.$ext";
    return { full => $full, image => $img1k, thumb => $thumb };
}

# --- read the manifest: slug -> ordered, de-duped list of photos --------------
my %photos;        # slug => [ {file, image, thumb}, ... ]
my %seen_file;     # slug => { rel => 1 }
open my $mh, '<:raw', $manifest or die "open $manifest: $!";
while (my $line = <$mh>) {
    $line =~ s/^\x{EF}\x{BB}\x{BF}//;   # tolerate a BOM
    next unless $line =~ /\S/;
    my $row = eval { decode_json($line) };
    next unless ref $row eq 'HASH';
    my $slug = $row->{slug} or next;
    my $rel  = $row->{file} or next;
    next if $seen_file{$slug}{$rel}++;
    my $u = urls_for($rel);
    push @{ $photos{$slug} }, $u;
}
close $mh;

# --- write image URLs into the matching catalog sidecars ----------------------
opendir(my $dh, $catalog_dir) or die "cannot open catalog dir $catalog_dir: $!";
my %has_sidecar = map { $_ => 1 } grep { /\.json$/ } readdir $dh;
closedir $dh;

my ($linked, $photo_total, %catalog_slugs) = (0, 0);
my $json = JSON::PP->new->utf8->canonical->pretty;

for my $slug (sort keys %photos) {
    my $file = "$slug.json";
    unless ($has_sidecar{$file}) {
        print "skip (no catalog item): $slug\n";
        next;
    }
    my $path = "$catalog_dir/$file";
    my $item = decode_json(slurp_raw($path));

    my @imgs  = map { $_->{image} } @{ $photos{$slug} };
    my $thumb = $photos{$slug}[0]{thumb};

    $item->{images} = \@imgs;
    $item->{thumb}  = $thumb;

    open my $ofh, '>:raw', $path or die "cannot write $path: $!";
    print $ofh $json->encode($item);
    close $ofh;

    $linked++;
    $photo_total += scalar @imgs;
    printf "linked %-34s %d photo(s)\n", $slug, scalar @imgs;
}

printf "\nlinked %d item(s), %d photo(s). Now run: perl generate_sayonara.pl\n", $linked, $photo_total;
