# Pull a Zoom registrant / participant list

Auth is a **Server-to-Server OAuth app** on Rob's Zoom account.
Credentials: `~/.config/zoom/robnugen_s2s.env` (override with `$ZOOM_CREDS`).
Vars: `ZOOM_ACCOUNT_ID`, `ZOOM_CLIENT_ID`, `ZOOM_CLIENT_SECRET`.

That file lives outside this repo on purpose.  Never cat it, never paste its
values into anything here.  Source it, and never echo the access token.

Reference implementation of the auth handshake: `zoom_schedule.pl:184-196`.

## Helper

```bash
#!/usr/bin/env bash
# zoomget.sh <api-path-after-/v2>
set -euo pipefail
set -a; . "${ZOOM_CREDS:-$HOME/.config/zoom/robnugen_s2s.env}"; set +a
TOK=$(curl -s -u "$ZOOM_CLIENT_ID:$ZOOM_CLIENT_SECRET" \
  -X POST "https://zoom.us/oauth/token?grant_type=account_credentials&account_id=$ZOOM_ACCOUNT_ID" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin).get("access_token",""))')
[ -n "$TOK" ] || { echo "NO TOKEN" >&2; exit 1; }
curl -s -H "Authorization: Bearer $TOK" "https://api.zoom.us/v2$1"
```

## Meeting ID

It is the number in the URL path, whatever the URL shape:

    zoom.us/meeting/86454236272?meetingMasterEventId=...   ->   86454236272

Ignore `meetingMasterEventId`, `pwd`, `tk`.

## Endpoints

| Want | Call |
|---|---|
| Confirm which meeting | `GET /meetings/{id}` |
| Who **signed up** | `GET /meetings/{id}/registrants?page_size=300&status=approved` |
| Who **attended** (past) | `GET /report/meetings/{id}/participants?page_size=300` |

Registrants also take `status=pending` and `status=denied` -- `approved` alone
can undercount.  Check `total_records` against what you return.

Paginate on `next_page_token`: non-empty means more, pass it back as
`&next_page_token=`.

## Gotchas

- **`"status":"waiting"` does NOT mean upcoming.**  It means "not live right
  now", and is the value both before and after a meeting.  To tell whether it
  already happened, compare `start_time` + `duration` against real time
  (`TZ=Asia/Tokyo date`).  Never infer past/future from `status`.

- **The report endpoint needs a scope the app may lack.**  Failure looks like:

      {"code":4711,"message":"Invalid access token, does not contain
       scopes:[report:read:list_meeting_participants:admin]."}

  Fix is Rob adding it at marketplace.zoom.us -> the S2S app -> Scopes.
  Error 4711 always names the exact scope it wanted, so don't guess -- same
  round-trip trick the scope notes in `robnugen_s2s.env` describe.

- **Recurring meetings** (Ring Ring is `type: 2`, but the series ones are not):
  registrants may need `&occurrence_id=<id>` taken from `occurrences[]` in
  `GET /meetings/{id}`.  Report participants keys off the meeting **UUID** for a
  specific instance -- URL-encode it, and double-encode when the UUID starts
  with `/` or contains `//`.

- Zoom returns names with trailing and doubled whitespace.  `.strip()` every
  field before printing or writing CSV.

- The same person can register twice under different emails.  Dedupe by name as
  well as email before reporting a count.

- Do not reach for Playwright.  A fresh browser profile is not logged in to
  Zoom and the meeting page renders empty.
