#!/usr/bin/perl
# generate_sayonara.pl — build Hugo item pages from the badmin catalog sidecars.
#
# Reads per-item JSON sidecars (the catalog source-of-record, written by badmin #4;
# for the initial batch, by export_issues_to_catalog.pl) and emits one
# content/sayonara/items/<slug>.en.md per item. Stripe buy URLs are merged in from
# a Boss-side stripe_links.json (keyed by slug), so badmin never holds Stripe data.
#
# Pure-local: no mg / network / secrets. English-only (v1).
#
# Env overrides:
#   SAYONARA_CATALOG  dir of *.json sidecars   (default ~/barefoot_rob_master/data/sayonara/items)
#   SAYONARA_STRIPE   stripe_links.json path   (default ~/barefoot_rob_master/data/sayonara/stripe_links.json)
#   SAYONARA_SALE     sale.json overlay path   (default ~/barefoot_rob_master/data/sayonara/sale.json)
#   SAYONARA_OUT      Hugo items dir           (default ~/barefoot_rob_master/content/sayonara/items)

use strict;
use warnings;
use utf8;
use JSON::PP;
use File::Path qw(make_path);

binmode STDOUT, ':encoding(UTF-8)';

my $home        = $ENV{HOME};
my $catalog_dir = $ENV{SAYONARA_CATALOG} // "$home/barefoot_rob_master/data/sayonara/items";
my $stripe_file = $ENV{SAYONARA_STRIPE}  // "$home/barefoot_rob_master/data/sayonara/stripe_links.json";
my $sale_file   = $ENV{SAYONARA_SALE}    // "$home/barefoot_rob_master/data/sayonara/sale.json";
my $out_dir     = $ENV{SAYONARA_OUT}     // "$home/barefoot_rob_master/content/sayonara/items";

make_path($out_dir) unless -d $out_dir;

# --- load Stripe links (optional) -------------------------------------------
my %stripe;
if (-f $stripe_file) {
    my $j = decode_json(slurp($stripe_file));
    %stripe = %$j if ref $j eq 'HASH';
}

# --- load Boss-set sale fields overlay (price/event/sold/…) -------------------
# Kept separate from the sidecars so re-scooping badmin sidecars never clobbers prices.
my %sale;
if (-f $sale_file) {
    my $j = decode_json(slurp($sale_file));
    %sale = %$j if ref $j eq 'HASH';
}

# --- YAML double-quote a scalar ---------------------------------------------
sub yq {
    my $s = shift;
    $s = '' unless defined $s;
    $s =~ s/\\/\\\\/g;
    $s =~ s/"/\\"/g;
    return qq{"$s"};
}

sub slurp {
    my $path = shift;
    local $/;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";  # bytes; decode_json handles UTF-8
    my $c = <$fh>;
    close $fh;
    return $c;
}

opendir(my $dh, $catalog_dir) or die "cannot open catalog dir $catalog_dir: $!";
my @files = sort grep { /\.json$/ } readdir $dh;
closedir $dh;

my $count = 0;
for my $f (@files) {
    my $item = decode_json(slurp("$catalog_dir/$f"));
    my $slug = $item->{slug};
    unless ($slug) { warn "skip $f: no slug\n"; next; }

    # Boss-set sale fields override the sidecar (price/event/sold/tier/mechanism/quantity)
    if (my $ov = $sale{$slug}) {
        for my $k (qw(name price_jpy event sold tier mechanism quantity pickup)) {
            $item->{$k} = $ov->{$k} if exists $ov->{$k};
        }
    }

    # off-market items (sale.json for_sale:false) keep their record but show no buy button
    my $off_market = (exists $sale{$slug} && defined $sale{$slug}{for_sale} && !$sale{$slug}{for_sale});

    my $sl = $off_market ? {} : ($stripe{$slug} // {});
    if ($off_market) { $item->{price_jpy} = undef; }

    my @fm = ("---");
    push @fm, "title: " . yq($item->{name} // $slug);
    push @fm, "slug: " . yq($slug);
    push @fm, "mg_issue_id: " . ($item->{mg_issue_id} ? $item->{mg_issue_id} + 0 : '""');
    push @fm, "category: " . yq($item->{category} // "");
    push @fm, "tier: " . yq($item->{tier} // "");
    push @fm, "mechanism: " . yq($item->{mechanism} // "");
    push @fm, "event: " . yq($item->{event} // "");
    push @fm, "pickup: " . yq($item->{pickup} // "");

    my @imgs = @{ $item->{images} // [] };
    if (@imgs) {
        push @fm, "images:";
        push @fm, "  - " . yq($_) for @imgs;
    } else {
        push @fm, "images: []";
    }
    push @fm, "thumb: " . yq($item->{thumb} // "");

    push @fm, "stripe_product_id: " . yq($sl->{product_id} // "");
    push @fm, "stripe_price_id: "   . yq($sl->{price_id}   // "");
    push @fm, "stripe_buy_url: "     . yq($sl->{buy_url}     // "");

    my $price = $item->{price_jpy};
    push @fm, (defined $price && $price ne '') ? "price_jpy: " . ($price + 0) : "price_jpy:";
    push @fm, "quantity: " . (($item->{quantity} // 1) + 0);
    push @fm, "sold: " . ($item->{sold} ? "true" : "false");
    push @fm, "draft: false";
    my $date = $item->{captured} ? substr($item->{captured}, 0, 10) : "2026-06-24";
    push @fm, "date: $date";
    push @fm, "---";

    my $body = $item->{description} // "";
    $body =~ s/\s+$//;

    my $md = join("\n", @fm) . "\n\n" . $body . "\n";

    my $out = "$out_dir/$slug.en.md";
    open my $ofh, '>:encoding(UTF-8)', $out or die "cannot write $out: $!";
    print $ofh $md;
    close $ofh;
    $count++;
    print "wrote $out\n";
}

print "generated $count item page(s) from $catalog_dir\n";
