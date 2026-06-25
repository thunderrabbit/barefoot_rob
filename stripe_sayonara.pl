#!/usr/bin/perl
# stripe_sayonara.pl — create one Stripe Payment Link per priced sayonara item.
#
# Per item (3-call chain):  product -> price -> payment_link
# Writes the buy URL (+ ids) into data/sayonara/stripe_links.json keyed by slug.
#
# Source of truth:
#   data/sayonara/items/<slug>.json   — name, images[], quantity   (badmin sidecar)
#   data/sayonara/sale.json           — price_jpy overlay          (Boss-set)
# Effective price = sale.json price, else sidecar price_jpy. null/0 -> skipped.
#
# Idempotent: a slug already present in stripe_links.json is skipped.
# JPY is ZERO-DECIMAL: unit_amount = yen exactly (1500 -> ¥1,500, no x100).
#
# Secret key: ~/.stripe/sayonara.conf (any line containing rk_/sk_..). Read onto
# curl's stdin via -K - so it never lands in argv (ps) or stdout/logs.
#
#   perl stripe_sayonara.pl            # DRY RUN — show what would be created
#   perl stripe_sayonara.pl --go       # actually call Stripe (test key)
#   perl stripe_sayonara.pl --go --yes-live   # required if key is sk_live/rk_live

use strict;
use warnings;
use JSON::PP;
use IPC::Open2;
use FindBin qw($RealBin);

my $GO        = grep { $_ eq '--go' }        @ARGV;
my $YES_LIVE  = grep { $_ eq '--yes-live' }  @ARGV;
my $SYNC_DESC = grep { $_ eq '--sync-desc' } @ARGV;   # update descriptions on already-linked products

my $DATA  = "$RealBin/data/sayonara";
my $ITEMS = "$DATA/items";
my $SALE  = "$DATA/sale.json";
my $LINKS = "$DATA/stripe_links.json";
my $CONF  = "$ENV{HOME}/.stripe/sayonara.conf";

# ---- secret key -------------------------------------------------------------
open my $cf, '<', $CONF or die "cannot read $CONF: $!\n";
my $conf = do { local $/; <$cf> }; close $cf;
my ($KEY) = $conf =~ /((?:rk|sk)_(?:test|live)_[A-Za-z0-9]+)/
    or die "no rk_/sk_ key found in $CONF\n";
my $LIVE = $KEY =~ /_live_/;
if ($LIVE && !$YES_LIVE) {
    die "REFUSING: $CONF holds a LIVE key. Re-run with --yes-live to use it.\n";
}
printf "Stripe mode: %s\n", $LIVE ? "*** LIVE ***" : "test (sandbox)";

# ---- load data --------------------------------------------------------------
sub slurp { open my $fh, '<:raw', $_[0] or die "open $_[0]: $!"; local $/; <$fh> }
my $J = JSON::PP->new->utf8->canonical->pretty;

my $sale  = -e $SALE  ? decode_json(slurp($SALE))  : {};
my $links = -e $LINKS ? decode_json(slurp($LINKS)) : {};

# ---- curl helper: key on stdin (-K -), never on argv ------------------------
sub stripe_api {
    my ($url, @form) = @_;
    my @cmd = ('curl', '-s', '-K', '-', $url);
    push @cmd, ('-d', $_) for @form;
    my ($out, $in);
    my $pid = open2($out, $in, @cmd);
    print $in qq{user = "$KEY:"\n};
    close $in;
    local $/; my $resp = <$out>; close $out;
    waitpid $pid, 0;
    my $data = eval { decode_json($resp) } // {};
    return $data;
}

sub head_ok {
    my ($u) = @_;
    my $code = `curl -s -o /dev/null -I -w '%{http_code}' \Q$u\E`;
    return $code =~ /^(2|3)\d\d$/;
}

# Pickup line for the Stripe checkout (plain text; mirrors the website note).
sub pickup_line {
    my ($p) = @_;
    return ($p // '') eq 'yurigaoka'
        ? "Pickup at Yurigaoka (Kawasaki) during the week."
        : "Pickup at Yurigaoka (Kawasaki) during the week, or Yoyogi Park on Sundays.";
}

# Build a plain-text Stripe product description from the sidecar markdown + terms.
sub build_desc {
    my ($item, $pickup) = @_;
    my $d = $item->{description} // '';
    $d =~ s/\*\*//g;                 # drop bold markers
    $d =~ s/^#+\s*//mg;              # drop markdown headers
    $d =~ s/^\s*[-*]\s+/\x{2022} /mg;# bullets -> •
    $d =~ s/\n{3,}/\n\n/g;           # collapse blank runs
    $d =~ s/^\s+|\s+$//g;
    my $note = "Price does not include shipping. " . pickup_line($pickup);
    $d = $d ne '' ? "$d\n\n$note" : $note;
    $d = substr($d, 0, 900) . "\x{2026}" if length($d) > 900;
    return $d;
}

# ---- iterate priced items ---------------------------------------------------
my @sidecars = sort glob "$ITEMS/*.json";
my ($made, $skipped, $errors) = (0, 0, 0);

for my $path (@sidecars) {
    my $item = decode_json(slurp($path));
    my $slug = $item->{slug} or next;

    # off-market: sale.json may keep the record (price + note) but flag for_sale:false
    if (exists $sale->{$slug} && defined $sale->{$slug}{for_sale} && !$sale->{$slug}{for_sale}) {
        next;
    }

    # sold (e.g. paid in person, not via Stripe): retire any live payment link so the
    # lingering buy URL can't sell it again. Marked in stripe_links.json so we do it once.
    my $sold = (exists $sale->{$slug} && defined $sale->{$slug}{sold}) ? $sale->{$slug}{sold} : $item->{sold};
    if ($sold) {
        if ($GO && $links->{$slug} && $links->{$slug}{payment_link} && !$links->{$slug}{sold}) {
            stripe_api("https://api.stripe.com/v1/payment_links/$links->{$slug}{payment_link}", "active=false");
            $links->{$slug}{sold} = JSON::PP::true;
            open my $w, '>:raw', $LINKS or die "write $LINKS: $!"; print $w $J->encode($links); close $w;
            print "x $slug  sold — deactivated Stripe link\n"; $made++;
        }
        next;
    }

    my $price = (exists $sale->{$slug} && defined $sale->{$slug}{price_jpy})
              ? $sale->{$slug}{price_jpy}
              : $item->{price_jpy};
    next unless defined $price && $price > 0;     # unpriced -> skip silently

    my $pickup = (exists $sale->{$slug} && defined $sale->{$slug}{pickup})
               ? $sale->{$slug}{pickup} : '';
    my $desc   = build_desc($item, $pickup);

    # quantity: sale.json overlay wins, else sidecar, else 1
    my $qty = (exists $sale->{$slug} && defined $sale->{$slug}{quantity} && $sale->{$slug}{quantity} > 0)
            ? $sale->{$slug}{quantity}
            : ($item->{quantity} && $item->{quantity} > 0 ? $item->{quantity} : 1);

    if ($links->{$slug} && $links->{$slug}{buy_url}) {
        my $old_amt = $links->{$slug}{amount_jpy} // 0;
        my $old_qty = $links->{$slug}{quantity}   // 1;
        if ($old_amt != $price || $old_qty != $qty) {
            # Stripe prices are immutable: make a NEW price + payment link on the
            # same product and retire the old link. Keeps prices in sync with sale.json.
            print "~ $slug  \x{a5}$old_amt/x$old_qty -> \x{a5}$price/x$qty; ",
                  ($GO ? "re-pricing" : "would re-price"), "\n";
            if ($GO) {
                if (my $oldpl = $links->{$slug}{payment_link}) {
                    stripe_api("https://api.stripe.com/v1/payment_links/$oldpl", "active=false");
                }
                my $prod = $links->{$slug}{product_id};
                my $pr = stripe_api('https://api.stripe.com/v1/prices',
                    "product=$prod", "unit_amount=$price", "currency=jpy");
                my $pl = stripe_api('https://api.stripe.com/v1/payment_links',
                    "line_items[0][price]=$pr->{id}", "line_items[0][quantity]=1",
                    "restrictions[completed_sessions][limit]=$qty",
                    "phone_number_collection[enabled]=true");
                if ($pr->{id} && $pl->{url}) {
                    $links->{$slug}{price_id}     = $pr->{id};
                    $links->{$slug}{payment_link} = $pl->{id};
                    $links->{$slug}{buy_url}      = $pl->{url};
                    $links->{$slug}{amount_jpy}   = $price + 0;
                    $links->{$slug}{quantity}     = $qty + 0;
                    open my $w, '>:raw', $LINKS or die "write $LINKS: $!"; print $w $J->encode($links); close $w;
                    print "  -> $pl->{url}\n"; $made++;
                } else {
                    print "  ! re-price failed: ", ($pr->{error}{message} // $pl->{error}{message} // 'unknown'), "\n";
                    $errors++;
                }
            } else { $made++; }
            next;
        }
        if ($SYNC_DESC && $links->{$slug}{product_id}) {
            print "~ $slug  ", ($GO ? "updating description" : "would update description"), "\n";
            if ($GO) {
                my $up = stripe_api("https://api.stripe.com/v1/products/$links->{$slug}{product_id}",
                    "description=$desc");
                if ($up->{id}) { print "  ok\n"; $made++; }
                else { print "  ! ", ($up->{error}{message} // 'failed'), "\n"; $errors++; }
            }
            next;
        }
        print "= $slug  already linked ($links->{$slug}{buy_url})\n";
        $skipped++;
        next;
    }

    my $name  = $item->{name} // $slug;
    my $img   = ($item->{images} && @{$item->{images}}) ? $item->{images}[0] : '';

    printf "+ %-50s ¥%s%s\n", $slug, $price, $img ? '' : '  (no image!)';

    if (!$GO) { $made++; next; }   # dry run

    if ($img && !head_ok($img)) {
        print "  ! image not reachable, skipping: $img\n";
        $errors++; next;
    }

    my $prod = stripe_api('https://api.stripe.com/v1/products',
        "name=$name", "description=$desc", ($img ? ("images[]=$img") : ()));
    unless ($prod->{id}) {
        print "  ! product failed: ", ($prod->{error}{message} // 'unknown'), "\n";
        $errors++; next;
    }

    my $pr = stripe_api('https://api.stripe.com/v1/prices',
        "product=$prod->{id}", "unit_amount=$price", "currency=jpy");
    unless ($pr->{id}) {
        print "  ! price failed: ", ($pr->{error}{message} // 'unknown'), "\n";
        $errors++; next;
    }

    my $pl = stripe_api('https://api.stripe.com/v1/payment_links',
        "line_items[0][price]=$pr->{id}",
        "line_items[0][quantity]=1",
        "restrictions[completed_sessions][limit]=$qty",
        "phone_number_collection[enabled]=true");
    unless ($pl->{url}) {
        print "  ! payment_link failed: ", ($pl->{error}{message} // 'unknown'), "\n";
        $errors++; next;
    }

    $links->{$slug} = {
        buy_url      => $pl->{url},      # field names match sayonara_generate.pl
        payment_link => $pl->{id},
        product_id   => $prod->{id},
        price_id     => $pr->{id},
        amount_jpy   => $price + 0,
        quantity     => $qty + 0,
        mode         => $LIVE ? 'live' : 'test',
    };
    print "  -> $pl->{url}\n";
    $made++;

    # persist after each success so a mid-run failure never loses links
    open my $w, '>:raw', $LINKS or die "write $LINKS: $!";
    print $w $J->encode($links);
    close $w;
}

print "\n";
if (!$GO) {
    print "DRY RUN — $made would be created, $skipped already linked. Re-run with --go.\n";
} else {
    print "Done: $made created, $skipped already linked, $errors errors.\n";
    print "Links: $LINKS\n";
}
