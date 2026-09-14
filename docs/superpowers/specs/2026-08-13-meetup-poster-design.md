
**Date:** 2026-08-13
**Goal:** Post Ring Ring workshop events to Rob's three Meetup groups from the
generated `.meetup.txt` files, without a Meetup Pro account.

## Why not the API

Meetup retired the open REST API. What remains is GraphQL at `api.meetup.com/gql`,
and creating the OAuth consumer needed to reach it requires an active **Meetup Pro**
subscription plus Meetup's approval. Rob has no Pro account, so the API is closed to
him. Browser automation against his own logged-in session is the remaining route.

## Scope

Three sessions x three groups = nine drafts.

| Session | Start | Registration |
|---|---|---|
| Wed 19 Aug 2026 afternoon | 14:00 | `…/8xEoKf3qQZqE2W-2vnfm4A` |
| Wed 19 Aug 2026 evening | 19:00 | `…/sncHt-PJQfS_bLmpzf5JWg` |
| Mon 31 Aug 2026 evening | 19:00 | `…/sizsdtuEQe2DVo3XnRHJcw` |

Groups: `tokyo-sol-barefoot-more`, `all-things-emotion`, `live-your-best-life`.

**MKP Japan is never posted to.** The guarantee is an opt-in allow-list
(`ALLOWED_GROUPS` in `parse.mjs`); a file naming any other group fails to parse, so
no browser opens. There is deliberately no denylist.

## Decisions

- **Drafts only.** The script fills the form and clicks *Save as draft*. Rob reviews
  and publishes by hand. Nothing goes public without his click.
- **Interactive, no parameters.** Menu-pick the session, menu-pick the groups —
  same feel as `generate_events.pl`.
- **Headings:** `# What will we do?` loses the `#` and the line is bolded via the
  editor toolbar.
- **Photo:** resolved from a local cache by loose stem match, downloaded only if absent.

## Template contract

`templates/event_templates/ring_ring/ring_ring.meetup.txt` was restructured to be
parseable while staying readable: a labelled header block, notes and manual-posting
steps in their own sections, and the posted body inside an explicit
`--- DESCRIPTION BEGINS … ENDS ---` fence.

Constraints imposed by `generate_events.pl` — violating any of these silently
corrupts output:

- `%s` is not sprintf. `generate_events.pl:312` runs
  `s/^(\Q$key\E: .*?)%s(.*)/…/im`, so only a line starting `title: ` **and**
  containing `%s` gets filled. Exactly one such line.
- `generate_events.pl:243` rewrites the first line matching `^date: ` with the
  *generation* timestamp. A `Date:` label is therefore unusable — the header uses
  `When:`. The original template dodged this by writing `date HUMANDATE` with no colon.
- `generate_events.pl:301-302` substitutes `episode_image` **non-globally**, so
  `Image:` must precede `Image alt:` or the first substitution eats the alt token.
- `EVENT_M`, `EVENT_D`, `EVENT_H` are global substitutions; no new label may start
  with `EVENT_`.

## Components

### `parse.mjs` — file to fields. No browser, no network.

Boundaries: header is everything above the fence; the body is what is inside it.
Unindented `Label: value` lines are fields; indented lines are prose and ignored.

Guards, all verified to fire:

| Guard | Trips on |
|---|---|
| Start + Duration vs End | the two disagreeing after a hand-edit |
| Weekday check | "Thursday 19 August 2026" (it is a Wednesday) |
| Allow-list | any group not among the three |
| URL shape | `Online link:` not `https://` |
| Required fields | a missing header line |
| Fence | file not regenerated from the new template |

### `image.mjs` — photo resolution

Normalises a filename to a stem by shaving size/variant suffixes
(`_1000`, `-thumb`, `_original`, `_1920x1080`), so the file's canonical
`life_is_calling_1000.png` finds a hand-placed `life_is_calling.png`. Largest
match wins. A non-matching name is refused, never silently substituted.

### `login.mjs` — one-time session capture

Saves `storageState` to `.auth/state.json` (chmod 600, gitignored).

**Signed-out detection must match `/register/` as well as `/login/`.** An early
version probed a group `/schedule/` page and tested only for `/login`; logged out,
Meetup redirects that page to `/register/`, so the check reported success while
signed out and saved a state file holding only `MEETUP_BROWSER_ID` and
`SIFT_SESSION_ID`. A real session carries ~22 cookies including `MEETUP_SESSION`
and `__meetup_auth_access_token`. The probe is now `/home/` plus a cookie assertion.

### `post.mjs` — the driver (not yet written)

## Recon findings — Meetup's create-event form, 2026-08-13

`https://www.meetup.com/<group>/schedule/` **is** the create-event page. It is a
single-page form, not a multi-step wizard. A "Start from" modal covers it on load
with *Duplicate last event* / *Start from scratch*; clicking scratch reveals the
empty form and creates nothing server-side.

| Field | Selector |
|---|---|
| Title | `input#title`, `data-testid=event-name-input` |
| Start date | button "Open date picker" |
| Start time | `input[type=time]`, aria-label "Edit start time" |
| Duration | button showing current value; options `1 hour`, `1.5 hours`, `2 hours`, `3 hours`, `Set an end time…` |
| Description | `div[contenteditable=true]` |
| Bold | toolbar button "Bold" (also Italic, Unordered list, Ordered list, Insert link) |
| Online | **tab** under Location: `In person` / `Online` / `Hybrid`(Pro) |
| Online link | appears on the Online tab, placeholder `https://zoom.us/` |
| Topics | `input` placeholder "Search topics (max 5)..." |
| RSVP window | `button[role=switch]`, a **sibling** of the span "Limit RSVP window" |
| Photo | button "Select" in the image panel |
| Save draft | `data-testid=event-save-draft-btn` |
| Preview / Publish | `event-preview-btn` / `event-publish-btn` |

Notes:

- Duration is a **dropdown of preset lengths**, not an end time. 90 minutes →
  `1.5 hours`. Anything not on the list needs `Set an end time…`.
- Rob's topics from the template do not all match Meetup's suggested chips for this
  group; the topic field is a search-and-select, max 5. Unmatched topics should be
  logged, not silently dropped.
- Day buttons in the date picker carry aria-labels like
  `Wednesday, August 19th, 2026`; month nav is `Go to the Previous/Next Month`.
  Past dates are `disabled`.

### Things that bit during implementation

- **OneTrust keeps a `[role=dialog]` in the DOM.** A bare
  `document.querySelector('[role=dialog]')` returns *its* dialog, not Meetup's.
  Scope every dialog query. (An early "the consent banner is blocking clicks"
  conclusion was wrong — the banner is collapsed to 2px; the real fault was an
  unscoped `hasText: 'Select'` matching OneTrust's hidden "Select All" button.)
- **There is a hidden `[contenteditable=true]`.** `.first()` selects it and every
  action times out as "element is not visible". Use `[contenteditable="true"]:visible`.
- **The sticky header and sticky action bar intercept clicks** on elements that are
  visible, enabled and stable. Scroll to centre and fall back to `dispatchEvent`.
- **The photo needs two commits.** Uploading the file opens a crop dialog; the image
  is not attached until *that dialog's* own Save is clicked. A bare
  `name: 'Save'` also matches the action bar, so scope it to the dialog.
- Locator gotcha: `hasText: /^Select$/` and `name: 'Select', exact: true` both match
  nothing; the button wraps its label in a span alongside an svg.

## Safety

- Drafts only; `event-publish-btn` is never clicked.
- Read-back assertion per field: fill, read back, compare, abort on mismatch.
- Duplicate guard: skip if the group already has an event/draft with that title+date.
- Screenshots per step to `runs/<timestamp>/`.
- `.auth/`, `.cache/`, `runs/`, `node_modules/` are gitignored.

## Verified so far

- All three `.meetup.txt` files parse; 8 headings each; no notes leak into the body.
- Six parser guards fire.
- Image resolution finds the 1.8 MB original from the `_1000` URL.
- Login captures a real session.
- Recon left **no drafts** on `tokyo-sol-barefoot-more`.
