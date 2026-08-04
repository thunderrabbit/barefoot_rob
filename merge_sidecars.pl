#!/usr/bin/perl
# merge_sidecars.pl — fold freshly scooped sidecars into the catalog, keeping local tags.
#
# scoop_sayonara.sh scp's b.rn's sidecars into a temp dir and calls this. badmin writes
# the item facts (name, category, images, description); the "tags" array that drives the
# /en/sayonara/ filter may only exist on the local copy, so a blind overwrite would drop
# it. This keeps the incoming file as the truth for everything EXCEPT tags:
#
#   incoming has tags            -> copy through byte-for-byte (upstream wins)
#   incoming has none, local has -> re-emit incoming with the local tags merged in
#   no local copy                -> copy through byte-for-byte (new item)
#
# Byte-for-byte in the common case matters: re-encoding every sidecar on every scoop
# would churn the git diff even when nothing changed.
#
# Usage: perl merge_sidecars.pl <incoming-dir> <catalog-dir>

use strict;
use warnings;
use utf8;
use JSON::PP;
use File::Copy qw(copy);

binmode STDOUT, ':encoding(UTF-8)';

my ($in_dir, $catalog_dir) = @ARGV;
die "usage: $0 <incoming-dir> <catalog-dir>\n" unless $in_dir && $catalog_dir;
die "no such incoming dir: $in_dir\n"          unless -d $in_dir;
die "no such catalog dir: $catalog_dir\n"      unless -d $catalog_dir;

sub slurp {
    my $path = shift;
    local $/;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";  # bytes; decode_json handles UTF-8
    my $c = <$fh>;
    close $fh;
    return $c;
}

sub has_tags {
    my $j = shift;
    return ref $j->{tags} eq 'ARRAY' && @{ $j->{tags} };
}

my ($copied, $merged) = (0, 0);
for my $path (sort glob "$in_dir/*.json") {
    my ($file) = $path =~ m{([^/]+)$};
    my $dest = "$catalog_dir/$file";

    my $incoming = decode_json(slurp($path));

    if (has_tags($incoming) || !-f $dest) {
        copy($path, $dest) or die "cannot copy $path -> $dest: $!";
        $copied++;
        next;
    }

    my $local = eval { decode_json(slurp($dest)) };
    unless ($local && has_tags($local)) {
        copy($path, $dest) or die "cannot copy $path -> $dest: $!";
        $copied++;
        next;
    }

    # Insert the local tags after the incoming file's "category" line, copying that
    # line's indentation and colon spacing, so the merge adds one line and nothing else.
    my $raw  = slurp($path);
    my $list = join(", ", map { my $t = $_; $t =~ s/(["\\])/\\$1/g; qq{"$t"} } @{ $local->{tags} });

    if ($raw =~ /^([ \t]*)"category"(\s*:\s*)/m) {
        my ($indent, $colon) = ($1, $2);
        $raw =~ s/^([ \t]*"category"\s*:\s*.*)$/$1\n$indent"tags"$colon\[$list],/m;
        eval { decode_json($raw); 1 }
            or die "merging tags into $file produced invalid JSON: $@";
        open my $ofh, '>:raw', $dest or die "cannot write $dest: $!";
        print $ofh $raw;
        close $ofh;
    } else {
        # No category line to anchor on — fall back to a full re-encode.
        $incoming->{tags} = $local->{tags};
        open my $ofh, '>:raw', $dest or die "cannot write $dest: $!";
        print $ofh JSON::PP->new->utf8->canonical->pretty->encode($incoming);
        close $ofh;
    }

    printf "kept local tags on %s (%s)\n", $incoming->{slug} // $file, join(" ", @{ $local->{tags} });
    $merged++;
}

printf "merged %d sidecar(s): %d copied, %d kept local tags\n", $copied + $merged, $copied, $merged;
