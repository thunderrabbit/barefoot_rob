#!/usr/bin/env node
// Re-sync the DESCRIPTION of events that already exist on Meetup, from the
// .meetup.txt the repo generated.  Interactive, like post.mjs: pick the
// session, pick the groups, confirm.  Nothing is hardcoded -- the event ids are
// looked up by title + start time (see drafts.mjs).
//
//   node meetup_poster/edit.mjs [--headed] [--allow-short]
//
// Never clicks Publish.
//
// WHY DESCRIPTION ONLY
// Title, date, time, duration, topics, photo and the RSVP window are the fields
// Rob finishes by hand before publishing, so re-syncing them would clobber that
// work.  The description is the one that changes in the repo and needs pushing
// back out.
//
// EDIT vs CREATE -- the three things that differ from fill.mjs:
//   1. Hydration.  The create form starts blank; the edit form starts with a
//      placeholder and fills in from the API seconds later.  Type too early and
//      the hydration lands on top of what you typed.  So: wait for the text to
//      stop changing before touching anything.
//   2. Clearing.  The editor is not empty.  Ctrl+A inside a contenteditable
//      selects only its own content, not the page, so Ctrl+A then Delete is
//      safe -- but the result is verified before anything is retyped.
//   3. Idempotence.  Running twice must be a no-op.  The current body is
//      compared with the file first, and an event that already matches is
//      skipped without being cleared, retyped, or saved.

import { chromium } from 'playwright';
import { existsSync, mkdirSync } from 'node:fs';
import { join, relative } from 'node:path';
import { parseMeetupFile, findMeetupFiles, ALLOWED_GROUPS } from './parse.mjs';
import { centerAndClick, descriptionEditor, descriptionText, normalizeBody, typeDescription } from './fill.mjs';
import { findEvent, openEditPage } from './drafts.mjs';
import { createAsk, pickFrom } from './ask.mjs';

const HERE = new URL('.', import.meta.url).pathname.replace(/\/$/, '');
const REPO = join(HERE, '..');
const STATE = join(HERE, '.auth', 'state.json');
const HEADED = process.argv.includes('--headed');
// A body under this many characters reads as Meetup's empty-state placeholder
// rather than a loaded draft.  Clearing that would mean typing into a form that
// is still hydrating.  Genuinely short descriptions need --allow-short.
const HYDRATED_MIN_CHARS = 200;
const ALLOW_SHORT = process.argv.includes('--allow-short');

/** Poll until the editor's text stops changing -- the API fill has landed. */
async function waitForBody(page, editor) {
  let last = null;
  let stable = 0;
  for (let i = 0; i < 30; i++) {
    const now = (await editor.innerText().catch(() => '')).trim();
    stable = now === last ? stable + 1 : 0;
    last = now;
    if (stable >= 2 && now) return now;
    await page.waitForTimeout(500);
  }
  return last || '';
}

/** The first line where two bodies diverge, for a one-glance diff. */
function firstDifference(want, got) {
  const a = want.split('\n');
  const b = got.split('\n');
  for (let i = 0; i < Math.max(a.length, b.length); i++) {
    if (a[i] !== b[i]) {
      return `line ${i + 1}\n        file: ${JSON.stringify(a[i] ?? '(end)')}\n        page: ${JSON.stringify(b[i] ?? '(end)')}`;
    }
  }
  return 'no difference';
}

async function syncDescription(page, ev, group, { mode, runDir, cache }) {
  const log = (m) => console.log(`   ${m}`);

  const form = await findEvent(page, group, ev, { cache, log });
  if (!page.url().includes(`/${form.id}/edit`)) await openEditPage(page, group, form.id, log);

  const editor = descriptionEditor(page);
  const current = await waitForBody(page, editor);
  const want = normalizeBody(descriptionText(ev.description));
  const got = normalizeBody(current);

  if (got === want) {
    log(`already matches the file (${current.length} chars) -- nothing to do`);
    return { id: form.id, status: 'unchanged' };
  }
  log(`differs from the file at ${firstDifference(want, got)}`);

  if (mode === 'compare') return { id: form.id, status: 'would change' };

  if (current.length < HYDRATED_MIN_CHARS && !ALLOW_SHORT) {
    throw new Error(
      `the editor holds only ${current.length} chars -- that is probably the placeholder, `
      + 'not a loaded draft. Refusing to clear it. Pass --allow-short if the description really is that short.');
  }

  await centerAndClick(page, editor, 'description editor');
  await page.waitForTimeout(300);
  await page.keyboard.press('Control+A');
  await page.keyboard.press('Delete');
  await page.waitForTimeout(300);
  const leftover = (await editor.innerText()).trim();
  if (normalizeBody(leftover) && normalizeBody(leftover) === got) {
    throw new Error(`the editor did not clear (${leftover.length} chars remain)`);
  }
  log('editor cleared');

  const wroteChars = await typeDescription(page, editor, ev.description);
  const after = normalizeBody((await editor.innerText()).trim());
  if (after !== want) {
    // Meetup does its own light munging (autolinks, smart quotes), so a close
    // match is reported rather than thrown; a big shortfall is a real failure.
    if (after.length < want.length * 0.9) {
      throw new Error(`rewrite came out wrong at ${firstDifference(want, after)}`);
    }
    log(`WARNING page text differs slightly from the file at ${firstDifference(want, after)}`);
  }
  log(`description rewritten (${wroteChars} chars)`);

  const shot = `${group}-${form.id}`;
  if (runDir) await page.screenshot({ path: join(runDir, `${shot}-rewritten.png`), fullPage: true }).catch(() => {});

  if (mode !== 'save') {
    log('NOT saved -- inspect, then Ctrl-C');
    return { id: form.id, status: 'rewritten, not saved' };
  }

  const saveBtn = page.locator('[data-testid=event-save-draft-btn]')
    .or(page.getByRole('button', { name: /^save as draft$/i }))
    .or(page.getByRole('button', { name: /^save$/i }));
  await centerAndClick(page, saveBtn.first(), 'Save');
  await page.waitForTimeout(4000);
  if (runDir) await page.screenshot({ path: join(runDir, `${shot}-after-save.png`), fullPage: true }).catch(() => {});
  log('saved');
  return { id: form.id, status: 'SAVED' };
}

// ------------------------------- the menu -------------------------------

const { ask, close: closeAsk } = await createAsk();

const parsed = [];
const skipped = [];
for (const f of findMeetupFiles(join(REPO, 'content', 'events'))) {
  try { parsed.push(parseMeetupFile(f)); }
  catch (err) { skipped.push({ f: relative(REPO, f), why: err.message.split('\n')[0] }); }
}
if (!parsed.length) {
  console.error('No parseable .meetup.txt files found.');
  for (const s of skipped) console.error(`  skipped ${s.f}\n    ${s.why}`);
  process.exit(1);
}
parsed.sort((a, b) => a.startIso.localeCompare(b.startIso));

if (skipped.length) console.log(`(${skipped.length} file(s) skipped -- not in the fenced template format)`);
console.log('\nSessions found:\n');
parsed.forEach((p, i) => console.log(`  ${String(i + 1).padStart(2)}. ${p.humanDate}  ${p.startTime}  ${p.title}`));

const pick = await ask('\nWhich to re-sync? (numbers separated by spaces, e.g. "1 2"): ');
const chosen = pickFrom(parsed, pick);
if (!chosen.length) { console.error('Nothing selected.'); closeAsk(); process.exit(1); }

console.log('\nGroups:');
ALLOWED_GROUPS.forEach((g, i) => console.log(`  ${i + 1}. ${g}`));
const gpick = await ask('Which groups? (numbers, or Enter for all three): ');
const groups = pickFrom(ALLOWED_GROUPS, gpick, { emptyMeansAll: true });
if (!groups.length) { console.error('No valid groups.'); closeAsk(); process.exit(1); }

const answer = (await ask('\n[c]ompare only, [r]ewrite one and stop so you can look, or [s]ave for real? (c/r/s): ')).trim();
const mode = /^s/i.test(answer) ? 'save' : /^r/i.test(answer) ? 'rewrite' : 'compare';

console.log('\nAbout to do this:');
for (const ev of chosen) for (const g of groups) {
  console.log(`  ${g}  <-  ${ev.humanDate} ${ev.startTime}  "${ev.title}"`);
}
console.log(`  mode: ${{
  compare: 'READ ONLY -- report what differs, change nothing',
  rewrite: 'rewrite the first match only, save nothing',
  save: 'rewrite and SAVE every match that differs',
}[mode]}`);
console.log('  Only the description is touched. Publish is never clicked.');
const go = await ask('\nProceed? (yes/no): ');
closeAsk();
if (!/^y(es)?$/i.test(go.trim())) { console.log('Stopped.'); process.exit(0); }

if (!existsSync(STATE)) {
  console.error('\nNo saved session. Run:  node meetup_poster/login.mjs');
  process.exit(1);
}

const runDir = join(HERE, 'runs', new Date().toISOString().replace(/[:.]/g, '-'));
mkdirSync(runDir, { recursive: true });

const browser = await chromium.launch({ headless: !HEADED });
const context = await browser.newContext({ storageState: STATE, viewport: { width: 1400, height: 1000 } });
const page = await context.newPage();

const cache = new Map();
const results = [];
outer:
for (const ev of chosen) {
  for (const g of groups) {
    console.log(`\n=== ${g}  <-  ${ev.humanDate} ${ev.startTime} ===`);
    const when = `${ev.humanDate} ${ev.startTime}`;
    try {
      const r = await syncDescription(page, ev, g, { mode, runDir, cache });
      results.push({ group: g, when, ...r });
      // In rewrite mode, stop at the first event we actually changed.
      if (mode === 'rewrite' && r.status.startsWith('rewritten')) break outer;
    } catch (err) {
      console.error(`   FAILED: ${err.message}`);
      await page.screenshot({ path: join(runDir, `${g}-FAILED.png`), fullPage: true }).catch(() => {});
      results.push({ group: g, when, status: 'FAILED', error: err.message });
    }
  }
}

console.log('\n================ summary ================');
for (const r of results) {
  console.log(`  ${r.status.padEnd(20)}  ${r.group}  ${r.when}${r.id ? `  #${r.id}` : ''}`);
  if (r.error) for (const line of r.error.split('\n')) console.log(`      ${line}`);
}
console.log(`  screenshots: ${relative(REPO, runDir)}`);
console.log('  nothing published');

if (mode === 'rewrite' && HEADED) {
  console.log('\nBrowser left open for inspection. Ctrl-C when done.');
  await new Promise(() => {});
}
await browser.close();
