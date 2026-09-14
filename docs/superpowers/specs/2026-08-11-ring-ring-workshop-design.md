# Ring Ring! Your Life is Calling! — event type design

## Context

Rob wrote a v0.1 brief for a new experimental webinar, "Ring Ring! Your Life is
Calling! Are You Willing to Answer?", and wants it wired into
`./generate_events.pl` so he can generate the event page + promo posts for two
planned experimental runs (~1 week out, and first weekend of September before
he leaves for Australia). Exact dates are still TBD — this spec only covers
scaffolding the event type; dates get filled in interactively when Rob
actually runs the generator.

The brief text itself must **not** be cleaned up or rewritten — it goes into
the templates verbatim.

## New event type: `ring_ring`

Modeled on `bold_life_tribe` (flat template list, no location submenu — this
event has one "location": Zoom) rather than the nested `cuddle_party` /
`walk_and_talk` pattern, since there's no location drill-down needed.

Appears in the `generate_events.pl` menu as `ring_ring`, sorted alphabetically
with the other event type keys.

## Template files

New directory `templates/event_templates/ring_ring/`:

- `ring_ring.en.md` — website event page
- `ring_ring.facebook.txt` — manual-paste Facebook event script
- `ring_ring.meetup.txt` — manual-paste Meetup event script
- `ring_ring.linkedin.txt` — manual-paste LinkedIn event script
- `ring_ring.eventbrite.txt` — manual-paste Eventbrite event script (doubles
  as the registration platform, since a registration link is TBD)

Each follows the placeholder conventions `generate_events.pl` already
substitutes: `%s` (title/tags/date front matter), `HUMANDATE`, `EVENT_TIME`,
`FIRST_GATHERING_TIME`, `episode_image`, `episode_image_alt`, `IMAGE_CREDIT`,
`EVENT_LOCATION_NAME`.

## Content approach

The body of `ring_ring.en.md` (and the description sections of the other
templates) contains Rob's brief text unedited — bullet points, the
podcast story, the "Was that podcast my perfect wake up call??" aside, all of
it — wrapped only with the standard front matter and placeholder markers
needed for date/image substitution. No copy editing.

## `rpl/Constants.pm` additions

- `%event_template_files{"ring_ring"}` → array of the 5 template files above
- `%event_locations{"ring_ring"}` → `"Zoom"`
- `%event_day_of_week{"ring_ring"}` and `%event_primary_time{"ring_ring"}` →
  placeholder seed values for the date-picker prompt (Rob types the real
  date/time interactively each run regardless)
- `%event_tag_hashes{"ring_ring"}` → `webinar`, `life-purpose`, `event`,
  `Barefoot Rob`, `裸足のロブ` (Rob can adjust freely — not load-bearing)
- No entry in `%event_title_prefixes` — Rob types a distinct title for each
  of the two runs
- `%gather_minutes_before_event` — no entry needed; falls back to the
  existing default of 15 minutes

## Front matter

`ring_ring.en.md` front matter matches the standard event shape (title, tags,
author, date, EventLocation, EventTime, TimeDescription, EventDate, aliases)
plus `EventType: "Webinar"`, which renders as a `[Webinar]` badge on the
event listing (same mechanism as `[Mindful Sayonara]`).

## Verification

After scaffolding, run `./generate_events.pl` once with throwaway test
answers to confirm the new menu entry walks through cleanly and produces
files without errors, then discard that test output. Rob runs it for real
once actual dates are locked in.
