# Event Calendar Links — Design

**Date:** 2026-08-11
**Status:** Approved, ready for implementation plan
**Scope:** `ring_ring` event type only, for now

## Problem

Every generated event knows exactly when it happens, but a visitor who wants that
event in their own calendar has to type it in by hand. Add "add to calendar"
links — Google, Outlook, and a downloadable `.ics` — to event pages.

## Constraints

These came out of brainstorming and bound the design:

- **Opt-in only.** Links appear only where a template asks for them. The ~158
  existing event pages are not touched and are not retroactively changed.
- **No Facebook / Meetup output.** Those platforms have their own calendar
  systems; people come back to the site for official information. Only the web
  page gets links.
- **`ring_ring` first.** Other event types adopt this later by adding two hash
  entries and template tokens.
- **Don't read templates earlier than the generator already does.** Prompting is
  gated on config data, not on template contents.

## Data Model

Three new front matter fields. Only opted-in templates carry them.

```yaml
title: "Ring Ring! Your Life is Calling.  Are You Willing to Answer?"
EventDate: "2026-08-19T19:00:00+09:00"                # existing
EventEndDate: "2026-08-19T20:30:00+09:00"             # new — start + duration
EventLocation: "Zoom"                                  # existing — human label
EventLocationURL: "https://us02web.zoom.us/j/8929…"    # new — Zoom/Meet/Maps link
TimeDescription: "Zoom doors open at 18:45; …"        # existing
outputs: ["HTML", "Calendar"]                          # new — opt in to the .ics
```

`EventLocationURL` is deliberately separate from `EventLocation`. `EventLocation`
is rendered as "in {{ .Params.EventLocation }}" by `layouts/index.html:27` and
`layouts/events/list.html:43`; putting a raw URL there would print a Zoom link on
the homepage.

`outputs` must list `"HTML"` explicitly — omitting it stops the page rendering as
HTML at all.

## Perl: `rpl/Constants.pm`

Two new per-event-type hashes, each supplying a prompt default:

```perl
our %event_duration_minutes = (
    "ring_ring" => 90,
);

our %event_location_urls = (
    "ring_ring" => "https://us02web.zoom.us/j/8929…",
);
```

Presence in these hashes **is** the opt-in switch for prompting.

## Perl: `generate_events.pl`

**Prompting.** If `$what_kinda_event` has an entry in `%event_duration_minutes`,
prompt for duration pre-filled with it. Same for `%event_location_urls`. Event
types absent from both hashes get no new prompts — generating a walk is unchanged.

Template files are not read any earlier than they are today.

**New token substitutions**, alongside the existing ones:

| Token | Expands to |
|---|---|
| `CALENDAR_LINKS` | `{{< calendar-links >}}` |
| `EVENT_END_DATETIME` | `2026-08-19T20:30:00+09:00` |
| `EVENT_LOCATION_URL` | the prompted URL |

`EVENT_LOCATION_URL` appears twice in the ring_ring template — in front matter and
in the body's `#### Where:` section — so the generated file has one source of
truth for the Zoom link.

**Validation.** After substitutions run on a template's output, scan for any
surviving `CALENDAR_LINKS`, `EVENT_END_DATETIME`, or `EVENT_LOCATION_URL`. If one
remains, die naming the template file and the unfilled token. A template that asks
for something the hashes don't supply fails at generation time, not silently on
the live site.

## Hugo: `layouts/shortcodes/calendar-links.html`

Builds all three links from the page's front matter and emits one inline line:

```
Add to calendar: Google · Outlook · .ics
```

Shared values across all three targets:

- **WHERE:** `{EventLocation} — {EventLocationURL}`, falling back to
  `{EventLocation}` alone when no URL is set. Phone calendars linkify the URL, so
  it stays tappable while the human label still reads well in month view.
- **Description / notes:** the `TimeDescription` line, then the event page
  permalink. Falls back to the permalink alone when `TimeDescription` is absent.
- **Title:** the page title.

Per-target construction:

- **Google:** `https://calendar.google.com/calendar/render?action=TEMPLATE` with
  `text`, `dates` (UTC `20060102T150405Z/20060102T150405Z`), `details`, `location`.
- **Outlook:** `https://outlook.live.com/calendar/0/deeplink/compose` with
  `path=/calendar/action/compose&rru=addevent`, `subject`, `startdt`, `enddt`
  (ISO 8601), `body`, `location`.
- **`.ics`:** the page's own Calendar output, via
  `.Page.OutputFormats.Get "calendar"`. Hugo's built-in Calendar format declares
  `protocol: webcal://`; if its `.Permalink` comes out as `webcal://`, use
  `.RelPermalink` so the link is an ordinary download.

All query parameters are URL-escaped.

## Hugo: `layouts/_default/single.calendar.ics`

Renders the VCALENDAR / VEVENT:

```
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//robnugen.com//events//EN
CALSCALE:GREGORIAN
BEGIN:VEVENT
UID:<permalink>
DTSTAMP:<build time, UTC>
DTSTART:<EventDate, UTC>
DTEND:<EventEndDate, UTC>
SUMMARY:<title>
LOCATION:<label — url>
DESCRIPTION:<TimeDescription\n permalink>
URL:<permalink>
END:VEVENT
END:VCALENDAR
```

RFC 5545 requires CRLF line endings and backslash-escaping of `,`, `;`, `\`, and
newlines inside text values.

This template lives site-wide but only ever renders for pages whose front matter
requests the Calendar output. The other 158 events never produce an `.ics`.

## Failure Modes

- **No `EventDate`:** the shortcode renders nothing at all.
- **No `EventEndDate`:** falls back to `EventDate + 1 hour`, so a hand-edited page
  cannot emit a zero-length or broken calendar entry.
- **No `EventLocationURL`:** WHERE is the `EventLocation` label alone.
- **Template token with no value:** the Perl generator dies, naming the file and
  the token.

## Verification

1. Regenerate from `event_generators/2026_aug_19_ring_ring.txt` and diff the
   result against the committed
   `content/events/2026/08/19ring-ring-your-life-is-calling.-are-you-willing-to-answer.en.md`.
2. Build with `hugo` and confirm the `.ics` is emitted for the ring_ring page and
   for no other event page.
3. Check the `.ics` against RFC 5545: CRLF endings, escaped text values, valid
   `DTSTART` / `DTEND`.
4. Follow the Google and Outlook links and confirm title, start, end, location,
   and notes all land correctly.
5. Run `./check_links.pl`.

## Out of Scope

- Retrofitting existing events.
- Facebook / Meetup text output.
- Calendar links on the events list page or homepage.
- Japanese (`.ja.md`) templates — `ring_ring` has no Japanese template today.
