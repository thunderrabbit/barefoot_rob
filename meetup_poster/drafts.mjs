// Find an already-created Meetup event so it can be edited.
//
// The create flow knows the group and invents the event; the edit flow has to
// go the other way -- the event id lives only on Meetup, never in the repo.
// Hardcoding ids into a script is what made the first edit script a throwaway,
// so this module looks them up instead, matching on the title and start time
// the .meetup.txt file already carries.
//
// Run directly to see what a group has:
//   node meetup_poster/drafts.mjs tokyo-sol-barefoot-more

import { dismissChatPopup } from './fill.mjs';

/** Collapse runs of whitespace so "Calling.  Are" matches "Calling. Are". */
const flat = (s) => (s || '').replace(/\s+/g, ' ').trim();
const loose = (s) => flat(s).toLowerCase().replace(/[^a-z0-9 ]/g, '');

/**
 * Every event Meetup will show us on the group's event pages, with whatever
 * text its card carried.  Drafts live behind ?type=draft; the plain listing is
 * checked too so a published event can be edited if that is ever wanted.
 */
export async function listGroupEvents(page, group, log = () => {}) {
  const seen = new Map();
  for (const url of [
    `https://www.meetup.com/${group}/events/?type=draft`,
    `https://www.meetup.com/${group}/events/`,
  ]) {
    await page.goto(url, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(3000);
    const found = await page.evaluate((g) => {
      const re = new RegExp(`/${g}/events/(\\d+)`);
      const out = [];
      for (const a of document.querySelectorAll('a[href*="/events/"]')) {
        const m = (a.getAttribute('href') || '').match(re);
        if (!m) continue;
        const card = a.closest('li, article, [data-testid], div');
        out.push({ id: m[1], cardText: (card?.innerText || a.innerText || '').slice(0, 400) });
      }
      return out;
    }, group);
    for (const f of found) {
      // First sighting wins: the drafts page is checked first and its cards are
      // the more informative ones.
      if (!seen.has(f.id)) seen.set(f.id, { id: f.id, cardText: f.cardText, listing: url });
    }
  }
  const all = [...seen.values()];
  log(`${group}: ${all.length} event(s) visible`);
  return all;
}

/**
 * Open one event's edit page and wait for the form to hydrate from the API.
 * Returns what the form actually holds -- the authority on which event this is.
 */
export async function openEditPage(page, group, id, log = () => {}) {
  await page.goto(`https://www.meetup.com/${group}/events/${id}/edit/`, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(3000);
  await dismissChatPopup(page, log);

  const titleBox = page.locator('#title');
  let title = '';
  for (let i = 0; i < 24; i++) {
    title = await titleBox.inputValue().catch(() => '');
    if (title.trim()) break;
    await page.waitForTimeout(500);
  }
  if (!title.trim()) throw new Error(`${group}/${id}: the edit form never showed a title`);

  const startTime = (await page.locator('input[type=time]').first().inputValue().catch(() => '')).slice(0, 5);
  return { id, group, title: title.trim(), startTime };
}

/**
 * The event in `group` that this parsed .meetup.txt describes.
 *
 * Title alone is not enough: "... Are You Willing to Answer?" is a prefix of
 * "... Are You Willing to Answer? (morning session)", so the two Ring Ring
 * sessions would collide.  Match the full title exactly and the start time too.
 *
 * `cache` is a Map the caller keeps for the run so one group is listed once.
 */
export async function findEvent(page, group, ev, { cache = new Map(), log = () => {}, probeLimit = 25 } = {}) {
  if (!cache.has(group)) cache.set(group, await listGroupEvents(page, group, log));
  const candidates = cache.get(group);
  if (!candidates.length) throw new Error(`${group}: no events visible -- is the session still logged in?`);

  // Cheap pre-filter on the card text so we do not open 25 edit pages.  The
  // card may be truncated or missing, so a miss falls back to probing all.
  const stem = loose(ev.title).slice(0, 40);
  let shortlist = candidates.filter((c) => loose(c.cardText).includes(stem));
  if (!shortlist.length) {
    shortlist = candidates.slice(0, probeLimit);
    log(`${group}: no card text matched "${flat(ev.title).slice(0, 40)}..." -- probing ${shortlist.length} edit page(s)`);
    if (candidates.length > probeLimit) {
      log(`${group}: WARNING only the first ${probeLimit} of ${candidates.length} were probed`);
    }
  }

  const probed = [];
  for (const c of shortlist) {
    const form = await openEditPage(page, group, c.id, log).catch((err) => {
      log(`${group}/${c.id}: skipped (${err.message})`);
      return null;
    });
    if (!form) continue;
    probed.push(form);
    if (flat(form.title) === flat(ev.title) && form.startTime === ev.startTime) {
      log(`${group}: matched event ${c.id} -- "${form.title}" at ${form.startTime}`);
      return form;
    }
  }

  const saw = probed.map((p) => `    ${p.id}  ${p.startTime}  ${p.title}`).join('\n') || '    (none)';
  throw new Error(
    `${group}: no event matches "${flat(ev.title)}" at ${ev.startTime}.\n  Saw:\n${saw}`);
}

if (import.meta.filename === process.argv[1]) {
  const { chromium } = await import('playwright');
  const { join } = await import('node:path');
  const HERE = new URL('.', import.meta.url).pathname.replace(/\/$/, '');
  const groups = process.argv.slice(2);
  if (!groups.length) {
    console.error('usage: node drafts.mjs <group-slug> [...]');
    process.exit(2);
  }
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ storageState: join(HERE, '.auth', 'state.json') });
  const page = await context.newPage();
  for (const g of groups) {
    console.log(`\n=== ${g} ===`);
    for (const e of await listGroupEvents(page, g, (m) => console.log(`  ${m}`))) {
      console.log(`  ${e.id}  ${flat(e.cardText).slice(0, 90)}`);
    }
  }
  await browser.close();
}
