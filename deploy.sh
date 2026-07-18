#!/bin/bash
# deploy.sh — one-shot Sayonara catalog deploy (run from the sayonara-items branch).
#
# Pipeline (strictly linear, no step repeats):
#   1 scoop    pull badmin sidecars from b.rn          (./scoop_sayonara.sh)
#   2 mint     create/refresh live Stripe links        (stripe_sayonara.pl --go --yes-live; idempotent)
#   3 generate build item pages from sidecars+links    (sayonara_generate.pl)
#   4 verify   local Hugo build, fail fast on errors   (hugo)
#   5 commit   commit catalog changes on sayonara-items
#   6 ship     master <- sayonara-items, push, then bbfr (builds from origin/master)
#
# Usage:  ./deploy.sh ["commit message"]
# Safe to re-run: scoop merges, mint skips already-linked, generate overwrites.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

BRANCH="sayonara-items"
MSG="${1:-Refresh sayonara catalog $(TZ=Asia/Tokyo date '+%d %b %Y %H:%M')}"

here="$(git branch --show-current)"
[ "$here" = "$BRANCH" ] || { echo "On '$here', expected '$BRANCH' — aborting."; exit 1; }

echo "==> 1/6 scoop sidecars from b.rn"
./scoop_sayonara.sh

echo "==> 2/6 mint live Stripe links (idempotent)"
perl stripe_sayonara.pl --go --yes-live

echo "==> 3/6 generate item pages"
perl sayonara_generate.pl

echo "==> 4/6 local Hugo build (verify before pushing)"
hugo --cleanDestinationDir >/dev/null
perl check_links.pl public

echo "==> 5/6 commit catalog changes"
git add data/sayonara content/sayonara
if git diff --cached --quiet; then
    echo "    nothing new to commit"
else
    git commit -q -m "$MSG"
    echo "    committed: $MSG"
fi

echo "==> 6/6 fast-forward master, push, deploy"
git checkout master
git merge --no-edit "$BRANCH"
git push
git checkout "$BRANCH"
ssh bfr '~/scripts/update_robnugen.com.sh'

echo "==> done."
