// Parse a generated .meetup.txt into the fields Meetup's create-event wizard needs.
//
// No browser, no network.  Run it directly to inspect what it extracted:
//   node meetup_poster/parse.mjs content/events/2026/08/19ring-ring*.meetup.txt

import { readFileSync } from 'node:fs';

const DESC_BEGIN = /^---\s*DESCRIPTION BEGINS\b/;
const DESC_END = /^---\s*DESCRIPTION ENDS\b/;
const GROUP_URL = /^https:\/\/www\.meetup\.com\/([a-z0-9-]+)\/schedule\/?$/i;

// A header field: unindented, "Label: value".  Indented lines are prose under
// "Notes --" / "By hand --" and are deliberately not fields.
const FIELD = /^([A-Za-z][A-Za-z ]*?):[ \t]+(.+?)[ \t]*$/;

/** The three groups this repo is allowed to post to.  Anything else is refused. */
export const ALLOWED_GROUPS = [
  'tokyo-sol-barefoot-more',
  'all-things-emotion',
  'live-your-best-life',
];

class ParseError extends Error {}

function parseDuration(text) {
  const h = text.match(/(\d+)\s*hours?/i);
  const m = text.match(/(\d+)\s*minutes?/i);
  if (!h && !m) throw new ParseError(`Cannot read a duration from "${text}"`);
  return (h ? +h[1] * 60 : 0) + (m ? +m[1] : 0);
}

const MONTHS = ['january', 'february', 'march', 'april', 'may', 'june', 'july',
  'august', 'september', 'october', 'november', 'december'];

/** "Wednesday 19 August 2026" + "14:00" -> { iso, weekdayClaimed } */
function parseWhen(whenText, timeText) {
  const m = whenText.match(/^([A-Za-z]+)[ ,]+(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]+)\s+(\d{4})$/);
  if (!m) throw new ParseError(`Cannot read a date from "${whenText}" (want "Wednesday 19 August 2026")`);
  const [, weekday, day, monthName, year] = m;
  const month = MONTHS.indexOf(monthName.toLowerCase());
  if (month < 0) throw new ParseError(`"${monthName}" is not a month name`);
  const t = timeText.match(/^(\d{1,2}):(\d{2})$/);
  if (!t) throw new ParseError(`Cannot read a time from "${timeText}" (want "14:00")`);
  const iso = `${year}-${String(month + 1).padStart(2, '0')}-${String(+day).padStart(2, '0')}`
    + `T${t[1].padStart(2, '0')}:${t[2]}:00+09:00`;
  return { iso, weekdayClaimed: weekday, date: new Date(iso) };
}

/** Split the posted body into lines, flagging which ones are headings. */
function parseDescription(lines) {
  return lines.map((raw) => {
    const heading = /^#\s+\S/.test(raw);
    return { text: heading ? raw.replace(/^#\s+/, '') : raw, heading };
  });
}

export function parseMeetupFile(path) {
  const text = readFileSync(path, 'utf8');
  const lines = text.split('\n');

  const beginAt = lines.findIndex((l) => DESC_BEGIN.test(l));
  const endAt = lines.findIndex((l) => DESC_END.test(l));
  if (beginAt < 0 || endAt < 0) {
    throw new ParseError(`${path}: missing DESCRIPTION BEGINS/ENDS fence — regenerate it from the template`);
  }
  if (endAt < beginAt) throw new ParseError(`${path}: DESCRIPTION ENDS comes before BEGINS`);

  const headerLines = lines.slice(0, beginAt);
  const bodyLines = lines.slice(beginAt + 1, endAt);

  // Trim blank lines off both ends of the body without touching interior spacing.
  while (bodyLines.length && !bodyLines[0].trim()) bodyLines.shift();
  while (bodyLines.length && !bodyLines[bodyLines.length - 1].trim()) bodyLines.pop();
  if (!bodyLines.length) throw new ParseError(`${path}: the description is empty`);

  const fields = new Map();
  for (const line of headerLines) {
    const m = line.match(FIELD);
    if (m) fields.set(m[1].toLowerCase(), m[2].trim());
  }
  const need = (key) => {
    const v = fields.get(key);
    if (!v) throw new ParseError(`${path}: header is missing "${key}:"`);
    return v;
  };

  const groups = headerLines
    .map((l) => l.trim().match(GROUP_URL))
    .filter(Boolean)
    .map((m) => m[1].toLowerCase());
  if (!groups.length) throw new ParseError(`${path}: no group URLs under "Post to:"`);

  const disallowed = groups.filter((g) => !ALLOWED_GROUPS.includes(g));
  if (disallowed.length) {
    throw new ParseError(
      `${path}: group(s) not on the allowed list: ${disallowed.join(', ')}\n`
      + `  allowed: ${ALLOWED_GROUPS.join(', ')}`);
  }

  const timezone = need('timezone');
  if (timezone !== 'Asia/Tokyo') {
    throw new ParseError(`${path}: only Asia/Tokyo is supported, got "${timezone}"`);
  }

  const start = parseWhen(need('when'), need('start'));
  const end = parseWhen(need('when'), need('end'));
  const durationMinutes = parseDuration(need('duration'));

  // The template states the end time twice over — once as End:, once implied by
  // Start + Duration.  A hand-edit that moves one and not the other stops here
  // rather than posting whichever the parser happened to read first.
  const impliedEnd = new Date(start.date.getTime() + durationMinutes * 60_000);
  if (impliedEnd.getTime() !== end.date.getTime()) {
    throw new ParseError(
      `${path}: Start + Duration disagrees with End.\n`
      + `  Start ${fields.get('start')} + ${durationMinutes} min = `
      + `${impliedEnd.toLocaleTimeString('en-GB', { timeZone: 'Asia/Tokyo', hour: '2-digit', minute: '2-digit' })}, `
      + `but End says ${fields.get('end')}`);
  }

  // Free sanity check: does the weekday the file claims match that calendar date?
  const actualWeekday = start.date.toLocaleDateString('en-US', { timeZone: 'Asia/Tokyo', weekday: 'long' });
  if (actualWeekday.toLowerCase() !== start.weekdayClaimed.toLowerCase()) {
    throw new ParseError(
      `${path}: "${fields.get('when')}" is a ${actualWeekday}, not a ${start.weekdayClaimed}`);
  }

  const onlineLink = need('online link');
  if (!/^https:\/\/\S+$/.test(onlineLink)) {
    throw new ParseError(`${path}: "Online link:" is not a URL: ${onlineLink}`);
  }

  // Meetup stores an absolute RSVP close moment, so "15 minutes before" has to
  // become a clock time.  Rob's rule: never later than 10 minutes before start.
  const rsvpText = need('rsvp closes');
  const rsvpMinutesBefore = parseDuration(rsvpText);
  if (rsvpMinutesBefore < 10) {
    throw new ParseError(
      `${path}: "RSVP closes: ${rsvpText}" is only ${rsvpMinutesBefore} min before the start; `
      + 'it must be at least 10 minutes before.');
  }
  const rsvpCloseAt = new Date(start.date.getTime() - rsvpMinutesBefore * 60_000);
  const hhmm = (d) => d.toLocaleTimeString('en-GB',
    { timeZone: 'Asia/Tokyo', hour: '2-digit', minute: '2-digit', hour12: false });

  return {
    path,
    groups,
    title: need('title'),
    startIso: start.iso,
    endIso: end.iso,
    startTime: fields.get('start'),
    endTime: fields.get('end'),
    humanDate: fields.get('when'),
    durationMinutes,
    timezone,
    isOnline: /^y(es)?$/i.test(need('online')),
    onlineLink,
    rsvpCloses: rsvpText,
    rsvpMinutesBefore,
    rsvpCloseTime: hhmm(rsvpCloseAt),
    rsvpCloseSameDay: rsvpCloseAt.toDateString() === start.date.toDateString(),
    imageUrl: need('image'),
    imageAlt: need('image alt'),
    topics: need('topics').split(',').map((t) => t.trim()).filter(Boolean),
    description: parseDescription(bodyLines),
  };
}

/** The body as Meetup would show it, for eyeballing before a run. */
export function descriptionAsText(parsed) {
  return parsed.description.map((l) => l.text).join('\n');
}

if (import.meta.filename === process.argv[1]) {
  const files = process.argv.slice(2);
  if (!files.length) {
    console.error('usage: node parse.mjs <file.meetup.txt> [...]');
    process.exit(2);
  }
  let failed = 0;
  for (const f of files) {
    try {
      const p = parseMeetupFile(f);
      console.log(JSON.stringify(p, null, 2));
    } catch (err) {
      failed++;
      console.error(`\n${err.message}\n`);
    }
  }
  process.exit(failed ? 1 : 0);
}
