#!/usr/bin/env perl
# check_links.pl — verify every internal link on the rendered site resolves.
#
# Renames break INBOUND links from pages you didn't touch, so this checks the
# whole link graph on Hugo's rendered output (fast: ~2s total for the site).
# Alias redirect stubs are real files in the output, so front matter aliases
# are validated automatically — and links that only work *via* an alias are
# reported as warnings with the canonical URL to point at instead.
#
# Usage:
#   ./check_links.pl                     build to a temp dir, then check
#   ./check_links.pl public              check an already-built directory
#   ./check_links.pl --update-baseline   rewrite known_broken_links.txt
#
# Exit 0: no broken links beyond the committed baseline (known_broken_links.txt).
# Exit 1: hugo build failed, or a link broke that is not in the baseline.
use strict;
use warnings;
use File::Find;
use File::Temp qw(tempdir);
use File::Basename qw(dirname);
use Cwd qw(abs_path);

my $repo = dirname(abs_path($0));
my $baseline_file = "$repo/known_broken_links.txt";

my $update_baseline = 0;
my $public;
for my $arg (@ARGV) {
    if ($arg eq '--update-baseline') { $update_baseline = 1; }
    elsif (-d $arg)                  { $public = abs_path($arg); }
    else { die "unknown argument or missing directory: $arg\n"; }
}

# The journal submodule lives on bitbucket; containers often don't have it.
# When it's absent, /journal/... targets can't render, so skip them.
my $have_journal = () = glob("$repo/content/journal/*");

if (!$public) {
    $public = tempdir(CLEANUP => 1);
    my $out = qx(cd "$repo" && hugo -d "$public" 2>&1);
    if ($? != 0) {
        print $out;
        die "FAIL: hugo build failed — the site would not deploy at all\n";
    }
}

my %valid;      # every URL path the site actually serves
my %alias_to;   # alias URL -> canonical URL (rendered redirect stubs)
my @html;

find(sub {
    return unless -f;
    my $rel = $File::Find::name;
    $rel =~ s/^\Q$public\E//;
    $valid{$rel} = 1;
    if ($rel =~ m{/index\.html$}) {
        (my $dir = $rel) =~ s{index\.html$}{};
        $valid{$dir} = 1;                         # /foo/
        (my $noslash = $dir) =~ s{/$}{};
        $valid{$noslash} = 1 if $noslash;         # /foo
    }
    push @html, $File::Find::name if /\.html$/;
}, $public);

# Alias stubs are pages whose whole job is a redirect (meta refresh + canonical).
for my $f (@html) {
    my $c = slurp($f) // next;
    next unless $c =~ /http-equiv="refresh"/;
    next unless $c =~ m{rel="canonical" href="([^"]+)"};
    my $canon = $1;
    (my $url = $f) =~ s/^\Q$public\E//;
    $url =~ s{index\.html$}{};
    $alias_to{$url} = $canon;
}

my (%broken, %via_alias);   # source page -> [targets]
my %broken_targets;
my $checked = 0;

for my $f (@html) {
    (my $src = $f) =~ s/^\Q$public\E//;
    (my $src_url = $src) =~ s{index\.html$}{};
    next if $alias_to{$src_url};                  # don't lint the stubs themselves
    my $c = slurp($f) // next;
    while ($c =~ /(?:href|src)="([^"]+)"/g) {
        my $url = decode_entities($1);
        $url =~ s/[#?].*$//;
        next unless length $url;
        if ($url =~ m{^https?://(?:www\.)?robnugen\.com(/.*)?$}) { $url = $1 // '/'; }
        elsif ($url =~ m{^(?:https?:)?//}) { next; }              # external
        elsif ($url =~ m{^(?:mailto|tel|javascript|data):}) { next; }
        elsif ($url !~ m{^/}) {                                   # relative link
            (my $base = $src_url) =~ s{[^/]*$}{};
            $url = normalize("$base$url");
        }
        $url =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;              # match on-disk names
        next if $url eq '/';           # site root is the language-redirect alias
        next if !$have_journal && $url =~ m{^/journal/};
        $checked++;
        if ($alias_to{$url} || ($url !~ m{/$} && $alias_to{"$url/"})) {
            push @{ $via_alias{$src} }, $url;
        } elsif (!$valid{$url}) {
            push @{ $broken{$src} }, $url;
            $broken_targets{$url} = 1;
        }
    }
}

print "checked $checked internal links across " . scalar(@html) . " pages\n";
print "note: /journal/ links skipped (submodule not initialized)\n" unless $have_journal;

if ($update_baseline) {
    open my $fh, '>', $baseline_file or die "cannot write $baseline_file: $!\n";
    print $fh "# Broken internal link targets grandfathered in by check_links.pl.\n";
    print $fh "# Regenerate with: ./check_links.pl --update-baseline\n";
    print $fh "# (Run that on a machine with the journal submodule for the authoritative list.)\n";
    print $fh "# Fix a link for real, then delete its line here.\n";
    print $fh "$_\n" for sort keys %broken_targets;
    close $fh;
    print "baseline written: $baseline_file (" . scalar(keys %broken_targets) . " known-broken targets)\n";
    exit 0;
}

my %baseline;
if (open my $fh, '<', $baseline_file) {
    while (<$fh>) { chomp; next if /^\s*(#|$)/; $baseline{$_} = 1; }
    close $fh;
}

my $new_breaks = 0;
for my $src (sort keys %broken) {
    my %seen;
    my @new = grep { !$baseline{$_} && !$seen{$_}++ } @{ $broken{$src} };
    next unless @new;
    $new_breaks += @new;
    print "BROKEN: $src\n";
    print "    -> $_\n" for @new;
}
my $baselined = grep { $baseline{$_} } keys %broken_targets;
print "($baselined known-broken targets covered by baseline)\n" if $baselined;

my %alias_hits;   # target -> { sources }
for my $src (keys %via_alias) {
    $alias_hits{$_}{$src} = 1 for @{ $via_alias{$src} };
}
for my $u (sort keys %alias_hits) {
    my @srcs = sort keys %{ $alias_hits{$u} };
    my $canon = $alias_to{$u} || $alias_to{"$u/"};
    my $more = @srcs > 1 ? " (+" . (@srcs - 1) . " more pages)" : "";
    print "WARN: $u works only via alias redirect — point at $canon\n";
    print "      linked from $srcs[0]$more\n";
}

if ($new_breaks) {
    print "FAIL: $new_breaks newly broken internal link(s)\n";
    exit 1;
}
print "OK: no broken internal links beyond baseline\n";
exit 0;

sub slurp {
    my ($f) = @_;
    open my $fh, '<', $f or return undef;
    local $/;
    my $c = <$fh>;
    close $fh;
    return $c;
}

sub decode_entities {
    my ($s) = @_;
    $s =~ s/&#x([0-9A-Fa-f]+);/chr(hex($1))/ge;
    $s =~ s/&#(\d+);/chr($1)/ge;
    my %ent = (amp => '&', lt => '<', gt => '>', quot => '"', apos => "'", nbsp => ' ');
    $s =~ s/&(amp|lt|gt|quot|apos|nbsp);/$ent{$1}/ge;
    return $s;
}

sub normalize {   # resolve ./ and ../ in a site-absolute path
    my ($p) = @_;
    my @out;
    my $trailing = $p =~ m{/$} ? '/' : '';
    for my $seg (split m{/}, $p) {
        next if $seg eq '' || $seg eq '.';
        if ($seg eq '..') { pop @out; next; }
        push @out, $seg;
    }
    return '/' . join('/', @out) . ($trailing && @out ? $trailing : $trailing);
}
