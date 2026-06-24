#!/bin/bash
# scoop_sayonara.sh — pull catalog sidecars written by the badmin #4 AI uploader.
#
# The /sayonara/ uploader (badmin) writes a per-item sidecar to b.rn at
# .../items/sidecars/<slug>.json when Rob files a new sale item. This pulls those
# into the site repo's catalog dir so generate_sayonara.pl can build their pages.
#
# Merges (never deletes): existing sidecars are left in place; new ones are added.
# After scooping:  perl link_sayonara_images.pl  (optional; sidecars already carry
#                  image URLs)  then  perl generate_sayonara.pl  then rebuild.

set -u
DEST="${SAYONARA_CATALOG:-$HOME/barefoot_rob_master/data/sayonara/items}"
REMOTE="${SAYONARA_SIDECARS_REMOTE:-b.rn:b.robnugen.com/home/tokyo/2026/p1/items/sidecars/*.json}"

mkdir -p "$DEST"
if scp -q "$REMOTE" "$DEST/" 2>/dev/null; then
    echo "scooped sidecars into $DEST"
else
    echo "no sidecars to scoop yet (none uploaded via #4), or scp unreachable"
fi
