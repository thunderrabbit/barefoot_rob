# DOTS internet two-player — design

Date: 2026-09-25 · Branch: `dots-multiplayer` (BEGIN `4fa5a44a`)

## Goal

Add "a human, across the internet" to the DOTS game at `/dots/`, beside the
existing hot-seat and computer opponents. Players find each other by share
link or through a public lobby of open games.

**Main constraint:** follow DreamHost shared-hosting rules and never
endanger the Hugo site. Polling must not start a process, nothing runs
long-lived, and a broken game must not break a build or deploy.

## Decisions (agreed in chat)

| Question | Decision |
|---|---|
| Finding an opponent | Share link **and** a public lobby of open games |
| Lobby listing | Creator chooses; "List in the lobby" checkbox, on by default |
| Player leaves mid-game | Game waits; seat token in `localStorage` resumes it; idle games swept after 7 days. No clocks, no forfeits, no resign |
| Architecture | Perl CGI for writes, static JSON files for reads |
| Rematch | Not in this version; "Play again" returns to setup |

## Server facts (checked on bfr, 2026-09-25)

- Perl 5.38.2, `JSON::PP` 4.16, `Digest::SHA` present. No non-core modules needed.
- CGI precedent: `~/robnugen.com.journal/journal.pl`, mode 775, `#!/usr/bin/perl`,
  no `.htaccess` handler. An executable `.pl` runs as CGI with no extra config.
- `/home` is local XFS (not NFS): `flock` and same-directory `rename()` are reliable.
- Web root `~/robnugen.com` is a symlink to a dated build dir, recreated by
  `~/scripts/update_robnugen.com.sh` (cron `@daily`, builds `master`). The script
  symlinks `journal` into each build; the 30-day cleanup matches only
  `robnugen.com-20*`.
- DreamHost adds `cache-control: max-age=600` to responses, so poll files need
  an explicit no-cache header.

## Architecture

```
~/dots_backend_since_2026_sep_25_tranmere/     survives deploys (outside dated builds)
  dots.pl          CGI, 755 — the only thing that writes
  .htaccess        no-cache on *.json; deny all but dots.pl and *.json
  .lock            flock target for every write
  open.json        lobby: listed, unjoined games
  ratelimit.json   salted IP hashes + timestamps
  games/<id>.json  public game state (polled)
  games/<id>.tok   seat tokens (never served)
```

- Served at `/dots-play/` through a symlink in each build, exactly like `journal`.
- Writes: `POST /dots-play/dots.pl?do=…`. Reads: `GET /dots-play/games/<id>.json`
  and `GET /dots-play/open.json` are plain static files, so Apache serves them with
  ETag/304 and no Perl process.
- `/dots/` stays pure static. Hugo output never contains game state.
- Source of truth is this repo: `server/dots/dots.pl` and `server/dots/htaccess`,
  outside `static/`, so Hugo never publishes them. There is no separate deploy
  path: `update_robnugen.com.sh` already pulls this repo on bfr, so after a
  successful Hugo build it copies both files into the data dir. `bbfr`,
  `./deploy.sh` and the nightly cron therefore all deploy the CGI.

### Deploy-script edit (show Rob before applying on bfr)

One variable, plus three lines after the journal symlink:

```bash
DOTS_DIR=/home/barefoot_rob/dots_backend_since_2026_sep_25_tranmere   # stable, never deleted
...
    ln -s $JOURNAL_DIR $ROBNUGENCOM_OUT_DIR/journal
    ln -s $DOTS_DIR $ROBNUGENCOM_OUT_DIR/dots-play
    install -m 755 $ROBNUGENCOM_SOURCE_DIR/server/dots/dots.pl $DOTS_DIR/dots.pl \
      && install -m 644 $ROBNUGENCOM_SOURCE_DIR/server/dots/htaccess $DOTS_DIR/.htaccess \
      || echo "DOTS CGI install failed; site deployed anyway"
```

These run only after Hugo succeeds, and a failure only logs a message; it never
blocks the site flip. `install` writes to a temp file and renames it, so a request
arriving mid-copy never sees a half-written `dots.pl`. Game data (`games/`,
`open.json`, etc.) is never touched by a deploy.

The live build dir also needs this symlink once, by hand, so the game works
before the next nightly build.

### `static/.htaccess` edit

Add `dots-play` to the "don't redirect to /en/" condition, so a swept game
returns a 404 and not an `/en/` redirect:

```
RewriteCond %{REQUEST_URI} !^/(en|ja|journal|dots-play)(/|$)
```

## API

All requests are JSON in, JSON out, with `Content-Type: application/json`.
Errors are `{"error":"…"}` with the status shown.

| do | body | success | failures |
|---|---|---|---|
| `create` | `w,h,name,color,listed` | `{id, token}` | 400 bad input · 429 rate · 503 caps |
| `join` | `id,name,color` | `{token}` | 400 bad input / colour clash ("Be original.") · 404 no game · 409 seat taken · 429 rate |
| `move` | `id,token,edge,after` | `{n}` | 400 bad/taken edge · 403 bad token or not your turn · 404 · 409 `after` ≠ move count |

The creator is player one (side 0) and moves first, as in hot-seat play.

**`games/<id>.json`:** `{"w","h","players":[{"name","color"},…],"moves":["h,1,1",…],"updated"}`.
`players` has one entry until someone joins.

**`open.json`:** `[{"id","w","h","name","color","created"}]`. A game is removed
from it on join, or when unjoined for more than 30 minutes.

**Edge format:** the existing canonical keys from `game.js`. `h,x,y` is the line
under box (x,y); `v,x,y` is the line left of it.

## Validation and security

- The id must match `^[a-f0-9]{12}$` **before** it is used in any path. User input
  never goes into a path otherwise.
- Ids (12 hex) and tokens (32 hex) come from `/dev/urandom`.
- Body ≤ 2 KB. `w`,`h` are integers 1–30. `color` is 1–15. `name` is 1–15 chars
  after trimming, with control chars stripped.
- `edge` must match `^[hv],\d+,\d+$`, be in bounds for w×h, and not already be
  drawn. Moves are capped at the total edge count.
- **Server-side turn check:** replay the move list, counting sides per box. A move
  that completes a box keeps the turn. The token must belong to the side to move.
- **Rate limits** (salted SHA-256 of `REMOTE_ADDR`; the salt lives in a file only
  the CGI reads): 10 creates and 20 joins per IP per hour, otherwise 429. Entries
  older than 1 hour are pruned on each write. Moves are not rate-limited, since
  turns already limit them.
- **Global caps:** ≤ 200 game files, ≤ 20 lobby entries. When full, `create`
  returns 503.
- **Sweep on every `create`:** delete games idle for more than 7 days and lobby
  entries unjoined for more than 30 minutes.
- **Writes:** take an exclusive `flock` on `.lock`, write to a temp file, then
  `rename()`.
- No shell-outs and no HTML output.
- `.htaccess` sets `Cache-Control: no-cache` on `*.json` and denies `.tok`,
  `ratelimit.json`, the salt and the lock file.

## Client (`static/dots/`)

**New `net.js`** holds all network code:
- `create`/`join`/`move` requests, and polling with `fetch(url, {cache:'no-cache'})`.
- Poll every 2 s while the opponent is to move, or while waiting for a joiner.
  Back off to 10 s after 5 minutes without change. Pause while
  `document.hidden`; poll once immediately on return.
- The seat `{id, token, side}` is saved in `localStorage` under the game id, with
  every access in try/catch. Without storage, a reload loses the seat.

**Setup screen (`index.html`, `game.js`):**
- `p2kind` gains "a human, across the internet". Choosing it hides player two's
  name and colour pickers and shows a "List in the lobby" checkbox (checked).
- "Play DOTS" creates the game. The share link `/dots/#g=<id>` appears in the
  message area with a Copy button, plus "waiting for someone to join…".
- An **Open games** list under the form, read from `open.json`: name, size and
  colour swatch, with a Join button.
- Joining asks only for your name and colour. A colour equal to the creator's gets
  "Be original. <name> already got <colour>."
- Loading `/dots/#g=<id>` resumes the game if `localStorage` holds a seat for it;
  otherwise it shows the join prompt. The hash keeps ids out of server logs.

**`game.js` hooks (net mode only):**
1. `commit()`: when it isn't your turn, refuse and show "waiting for <name>…". On
   your turn, apply the move locally, then POST it. On 409, rebuild from the
   server's list.
2. Poll: when the server list is longer than the local one, rebuild by replaying
   `play()` over the whole list, then redraw. Do not diff or patch.
3. Quit leaves the game (the seat stays in `localStorage`). Play again returns to
   setup.

Hot-seat and computer play keep their current code paths unchanged.

**Safety:** network-supplied names are shown only through `textContent`.
`ask()` uses `innerHTML`, so its questions never include a network-supplied name.

**Style:** keep the 1990 feel. No spinners; reuse the existing panel, `.msg`
and `.key` styles.

## Failure isolation

- If `dots.pl` is broken or missing, only internet play fails, with a message in the
  setup area. `/dots/` hot-seat and computer play and the rest of the site are
  unaffected.
- If the symlink step fails, it happens after a successful Hugo build, so the site
  still deploys.
- `check_links.pl` runs from the pre-commit hook whenever `static/` changes.
  `/dots-play/` URLs are built by script, not linked from HTML.

## Testing

1. **CGI with `curl`** before any client code. Check create, join, colour clash,
   legal move, stale `after` (409), wrong token (403), out-of-turn move (403),
   taken edge (400), bogus id such as `../x` (400, and no file created outside
   `games/`), rate limit (429), `.tok` not fetchable (403), and a 304 on an
   unchanged poll.
2. **Playwright with two browser contexts** playing a full 2×2 game against each
   other through the live endpoint. Both canvases must match pixel-for-pixel and
   both must show the same winner. Also test reloading mid-game to resume, and
   joining through the lobby.
3. **Regression:** a hot-seat game and a computer game still play to the end.

## Out of scope

Rematch, resign, turn clocks, chat, accounts, spectators, and moderating lobby names
beyond length and control-character limits.
