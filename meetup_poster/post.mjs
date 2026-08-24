#!/usr/bin/env node
// Post Ring Ring events to Meetup as drafts.  Interactive: pick the session,
// pick the groups, confirm.  No arguments to remember.
//
//   node meetup_poster/post.mjs
//
// Never clicks Publish.  See docs/superpowers/specs/2026-08-13-meetup-poster-design.md

import { chromium } from 'playwright';
import { existsSync, mkdirSync } from 'node:fs';
import { join, relative } from 'node:path';
import { parseMeetupFile, findMeetupFiles, ALLOWED_GROUPS } from './parse.mjs';
import { fillEvent } from './fill.mjs';
import { createAsk, pickFrom } from './ask.mjs';

const HERE = new URL('.', import.meta.url).pathname.replace(/\/$/, '');
const REPO = join(HERE, '..');
const STATE = join(HERE, '.auth', 'state.json');

const { ask, close: closeAsk } = await createAsk();

// Only files in the new fenced format parse; older ones are listed as skipped.
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

if (skipped.length) console.log(`(${skipped.length} file(s) skipped — not in the fenced template format)`);
console.log('\nSessions found:\n');
parsed.forEach((p, i) => console.log(`  ${String(i + 1).padStart(2)}. ${p.humanDate}  ${p.startTime}  ${p.title}`));

const pick = await ask('\nWhich to post? (numbers separated by spaces, e.g. "1 2"): ');
const chosen = pickFrom(parsed, pick);
if (!chosen.length) { console.error('Nothing selected.'); closeAsk(); process.exit(1); }

console.log('\nGroups:');
ALLOWED_GROUPS.forEach((g, i) => console.log(`  ${i + 1}. ${g}`));
const gpick = await ask('Which groups? (numbers, or Enter for all three): ');
const groups = pickFrom(ALLOWED_GROUPS, gpick, { emptyMeansAll: true });
if (!groups.length) { console.error('No valid groups.'); closeAsk(); process.exit(1); }

const mode = await ask('\n[f]ill one and stop so you can look, or [s]ave drafts for real? (f/s): ');
const save = /^s/i.test(mode.trim());

console.log('\nAbout to do this:');
for (const ev of chosen) for (const g of groups) {
  console.log(`  ${g}  <-  ${ev.humanDate} ${ev.startTime}  "${ev.title}"`);
}
console.log(`  mode: ${save ? 'FILL AND SAVE AS DRAFT' : 'fill the first one only, save nothing'}`);
console.log('  Publish is never clicked.');
const go = await ask('\nProceed? (yes/no): ');
closeAsk();
if (!/^y(es)?$/i.test(go.trim())) { console.log('Stopped.'); process.exit(0); }

if (!existsSync(STATE)) {
  console.error('\nNo saved session. Run:  node meetup_poster/login.mjs');
  process.exit(1);
}

const runDir = join(HERE, 'runs', new Date().toISOString().replace(/[:.]/g, '-'));
mkdirSync(runDir, { recursive: true });

const browser = await chromium.launch({ headless: false });
const context = await browser.newContext({ storageState: STATE, viewport: { width: 1400, height: 1000 } });
const page = await context.newPage();

const results = [];
outer:
for (const ev of chosen) {
  for (const g of groups) {
    console.log(`\n=== ${g}  <-  ${ev.humanDate} ${ev.startTime} ===`);
    try {
      const r = await fillEvent(page, ev, g, { save, runDir });
      results.push({ group: g, when: `${ev.humanDate} ${ev.startTime}`, ...r });
    } catch (err) {
      console.error(`   FAILED: ${err.message}`);
      await page.screenshot({ path: join(runDir, `${g}-FAILED.png`), fullPage: true }).catch(() => {});
      results.push({ group: g, when: `${ev.humanDate} ${ev.startTime}`, saved: false, error: err.message });
    }
    if (!save) break outer;
  }
}

console.log('\n================ summary ================');
for (const r of results) {
  console.log(`  ${r.saved ? 'DRAFT SAVED' : r.error ? 'FAILED     ' : 'filled only'}  ${r.group}  ${r.when}`);
  if (r.error) console.log(`      ${r.error.split('\n')[0]}`);
  if (r.missed?.length) console.log(`      topics not matched: ${r.missed.join(', ')}`);
  if (r.photoNote && r.photoNote !== 'skipped') console.log(`      photo: ${r.photoNote}`);
}
console.log(`  screenshots: ${relative(REPO, runDir)}`);
console.log('  nothing published; set the RSVP window by hand before publishing');

if (!save) {
  console.log('\nBrowser left open for inspection. Ctrl-C when done.');
  await new Promise(() => {});
}
await browser.close();
