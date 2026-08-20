// Fills Meetup's create-event form for one event in one group.
// Knows nothing about menus — post.mjs handles the asking, this does the doing.

import { join, relative } from 'node:path';
import { resolveImage } from './image.mjs';

const HERE = new URL('.', import.meta.url).pathname.replace(/\/$/, '');
const REPO = join(HERE, '..');
const CACHE = join(HERE, '.cache');

/** Scroll the target to the middle, away from the sticky header and action bar. */
export async function centerAndClick(page, locator, what) {
  await locator.scrollIntoViewIfNeeded();
  await page.evaluate(() => window.scrollBy(0, -180));
  await page.waitForTimeout(250);
  try {
    await locator.click({ timeout: 8000 });
  } catch {
    // Sticky chrome eats clicks; dispatch straight at the element instead.
    await locator.dispatchEvent('click');
  }
  if (what) console.log(`      clicked ${what}`);
}

const ORD = (d) => {
  if (d % 10 === 1 && d !== 11) return `${d}st`;
  if (d % 10 === 2 && d !== 12) return `${d}nd`;
  if (d % 10 === 3 && d !== 13) return `${d}rd`;
  return `${d}th`;
};

/** "Wednesday, August 19th, 2026" — matches the day button's aria-label. */
export function dayLabel(iso) {
  const d = new Date(iso);
  const f = (o) => d.toLocaleDateString('en-US', { timeZone: 'Asia/Tokyo', ...o });
  return `${f({ weekday: 'long' })}, ${f({ month: 'long' })} ${ORD(+f({ day: 'numeric' }))}, ${f({ year: 'numeric' })}`;
}

export const DURATIONS = { 60: '1 hour', 90: '1.5 hours', 120: '2 hours', 180: '3 hours' };

export async function fillEvent(page, ev, group, { save = false, runDir } = {}) {
  const log = (m) => console.log(`   ${m}`);

  await page.goto(`https://www.meetup.com/${group}/schedule/`, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(3500);

  const scratch = page.getByText('Start from scratch', { exact: false });
  if (await scratch.count()) {
    await scratch.first().click();
    await page.waitForTimeout(2500);
    log('started from scratch');
  }

  // --- dismiss "Event chat is here" beta popup (new as of ~2026-08-20) ---
  // It covers the title field, so an unfilled title read-back mismatch upstream
  // of here is usually this. The dialog has no aria-label on its close icon, so
  // pick the small (<=24px) icon button nearest the dialog's top-right corner.
  const chatDlg = page.locator('[role=dialog]').filter({ hasText: 'Event chat is here' });
  if (await chatDlg.count()) {
    const dlgBox = await chatDlg.first().boundingBox();
    const icons = chatDlg.locator('button');
    const n = await icons.count();
    let closeBtn = null;
    let bestX = -Infinity;
    for (let i = 0; i < n; i++) {
      const b = icons.nth(i);
      const box = await b.boundingBox().catch(() => null);
      if (!box || box.width > 24 || box.height > 24) continue;
      if (dlgBox && box.y - dlgBox.y > 80) continue;
      if (box.x > bestX) { bestX = box.x; closeBtn = b; }
    }
    if (closeBtn) await closeBtn.click();
    else await page.keyboard.press('Escape');
    await page.waitForTimeout(600);
    log('dismissed "Event chat is here" popup');
  }

  // --- title ---
  const title = page.locator('#title');
  await title.fill(ev.title);
  const gotTitle = await title.inputValue();
  if (gotTitle.trim() !== ev.title.trim()) {
    throw new Error(`title read-back mismatch:\n    wanted: ${ev.title}\n    got   : ${gotTitle}`);
  }
  log('title set');

  // --- date ---
  const want = dayLabel(ev.startIso);
  await centerAndClick(page, page.getByRole('button', { name: /open date picker/i }).first());
  await page.waitForTimeout(1200);
  let day = page.getByRole('button', { name: want, exact: true });
  for (let i = 0; i < 12 && !(await day.count()); i++) {
    await page.getByRole('button', { name: /Go to the Next Month/i }).first().click();
    await page.waitForTimeout(600);
    day = page.getByRole('button', { name: want, exact: true });
  }
  if (!(await day.count())) throw new Error(`date picker never showed "${want}"`);
  if (await day.first().isDisabled().catch(() => false)) throw new Error(`"${want}" is disabled (past date?)`);
  await day.first().click();
  await page.waitForTimeout(1000);
  log(`date set: ${want}`);

  // --- start time ---
  const time = page.locator('input[type=time]').first();
  await time.fill(ev.startTime);
  const gotTime = await time.inputValue();
  if (!gotTime.startsWith(ev.startTime)) {
    throw new Error(`time read-back mismatch: wanted ${ev.startTime}, got ${gotTime}`);
  }
  log(`start time set: ${ev.startTime}`);

  // --- duration ---
  const label = DURATIONS[ev.durationMinutes];
  if (!label) throw new Error(`no preset for ${ev.durationMinutes} min (have ${Object.values(DURATIONS).join(', ')})`);
  await centerAndClick(page, page.getByRole('button', { name: /^\d+(\.\d+)?\s*(hour|minute)/i }).first());
  await page.waitForTimeout(900);
  const opt = page.getByRole('option', { name: label, exact: true })
    .or(page.getByRole('menuitem', { name: label, exact: true }))
    .or(page.locator('li').filter({ hasText: new RegExp(`^${label}$`) }));
  if (!(await opt.count())) throw new Error(`duration option "${label}" not offered`);
  await opt.first().click();
  await page.waitForTimeout(800);
  await page.keyboard.press('Escape'); // close the popover before touching the editor
  await page.waitForTimeout(400);
  log(`duration set: ${label}`);

  // --- description, bolding the heading lines ---
  // Must be :visible — there is a hidden contenteditable that .first() otherwise wins.
  const editor = page.locator('[contenteditable="true"]:visible').first();
  await centerAndClick(page, editor);
  await page.waitForTimeout(400);
  const bold = page.getByRole('button', { name: 'Bold', exact: true }).first();
  for (let i = 0; i < ev.description.length; i++) {
    const line = ev.description[i];
    if (line.heading && line.text) {
      await bold.click();
      await page.keyboard.type(line.text);
      await bold.click();
    } else if (line.text) {
      await page.keyboard.type(line.text);
    }
    if (i < ev.description.length - 1) await page.keyboard.press('Enter');
  }
  const wroteChars = (await editor.innerText()).replace(/\s+/g, ' ').trim().length;
  const wantChars = ev.description.map((l) => l.text).join(' ').replace(/\s+/g, ' ').trim().length;
  if (wroteChars < wantChars * 0.9) {
    throw new Error(`description looks truncated: ${wroteChars} chars in editor vs ${wantChars} expected`);
  }
  log(`description written (${wroteChars} chars, ${ev.description.filter((l) => l.heading).length} bold headings)`);

  // --- online tab + link ---
  const onlineTab = page.getByRole('tab', { name: /^online$/i }).first()
    .or(page.getByText(/^Online$/).first());
  await centerAndClick(page, onlineTab, 'Online tab');
  await page.waitForTimeout(1500);
  const linkBox = page.locator('input[placeholder*="zoom" i]').first();
  if (!(await linkBox.count())) throw new Error('Online tab did not reveal the link field');
  await linkBox.fill(ev.onlineLink);
  const gotLink = await linkBox.inputValue();
  if (gotLink.trim() !== ev.onlineLink.trim()) {
    throw new Error(`online link read-back mismatch:\n    wanted: ${ev.onlineLink}\n    got   : ${gotLink}`);
  }
  log('online link set');

  // --- topics (search-and-select, max 5) ---
  const topicBox = page.locator('input[placeholder*="Search topics" i]').first();
  const missed = [];
  if (await topicBox.count()) {
    for (const t of ev.topics.slice(0, 5)) {
      // Meetup disables the search box once 5 topics are chosen.
      if (!(await topicBox.isEnabled().catch(() => false))) { missed.push(`${t} (limit reached)`); continue; }
      await topicBox.fill(t);
      await page.waitForTimeout(1400);
      const hit = page.getByRole('button', { name: t, exact: true })
        .or(page.getByRole('option', { name: t, exact: true }));
      if (await hit.count()) { await hit.first().click(); await page.waitForTimeout(600); }
      else missed.push(t);
    }
    if (await topicBox.isEnabled().catch(() => false)) await topicBox.fill('');
  }
  log(missed.length ? `topics set, NOT matched: ${missed.join(', ')}` : 'topics set');

  // --- photo ---
  let photoNote = 'skipped';
  try {
    const img = await resolveImage(ev.imageUrl, CACHE);
    const selectBtn = page.locator('button').filter({ has: page.locator('span', { hasText: /^Select$/ }) }).first();
    if (await selectBtn.count()) {
      const chooserP = page.waitForEvent('filechooser', { timeout: 6000 }).catch(() => null);
      await centerAndClick(page, selectBtn, 'photo Select');
      const chooser = await chooserP;
      if (chooser) {
        await chooser.setFiles(img.path);
        photoNote = `uploaded ${relative(REPO, img.path)}`;
      } else {
        await page.waitForTimeout(1500);
        const fileInput = page.locator('input[type=file]').first();
        if (await fileInput.count()) {
          await fileInput.setInputFiles(img.path);
          photoNote = `uploaded ${relative(REPO, img.path)}`;
        } else {
          photoNote = 'photo dialog opened but no file input found — add by hand';
          await page.keyboard.press('Escape');
        }
      }
      // The upload opens a crop dialog; the photo is not attached until its
      // own Save is clicked.  Without this the form looks filled but has no image.
      await page.waitForTimeout(2500);
      // Scope to the crop dialog itself — a bare name=Save also matches the
      // sticky action bar, whose overlay then swallows the click.
      const cropDlg = page.locator('[role=dialog]')
        .filter({ has: page.getByRole('button', { name: 'Cancel', exact: true }) }).last();
      const cropSave = cropDlg.getByRole('button', { name: 'Save', exact: true });
      if (await cropSave.count()) {
        await cropSave.first().click({ force: true }).catch(() => cropSave.first().dispatchEvent('click'));
        await page.waitForTimeout(4000);
      } else {
        photoNote += ' (no crop-dialog Save found)';
      }
      // Confirm an image really landed on the form.
      const attached = await page.locator('img[src*="secure-content"], img[src*="meetupstatic"], [data-testid*=image] img')
        .filter({ visible: true }).count();
      if (!attached) photoNote += ' — WARNING: no image visible on the form afterwards';
    } else {
      photoNote = 'photo Select button not found';
    }
  } catch (err) {
    photoNote = `failed: ${err.message}`;
  }
  log(`photo: ${photoNote}`);

  // --- RSVP close time ---
  // Meetup stores an absolute moment, so "15 minutes before" is already resolved
  // to a clock time by the parser.  The switch is a sibling of the label span and
  // the sticky chrome eats normal clicks, so flip it in the DOM.
  let rsvpNote;
  try {
    const flipped = await page.evaluate(() => {
      const span = [...document.querySelectorAll('span')].find((s) => s.textContent.trim() === 'Limit RSVP window');
      const sw = span?.closest('div')?.parentElement?.querySelector('button[role=switch]');
      if (!sw) return false;
      sw.scrollIntoView({ block: 'center' });
      if (sw.getAttribute('aria-checked') !== 'true') sw.click();
      return true;
    });
    if (!flipped) throw new Error('could not find the "Limit RSVP window" switch');
    await page.waitForTimeout(2500);

    // Three time inputs once the window is open: event start, RSVP open, RSVP close.
    const times = page.locator('input[type=time]:visible');
    const n = await times.count();
    if (n < 3) throw new Error(`expected 3 time inputs after opening the RSVP window, saw ${n}`);
    const closeTime = times.nth(n - 1);
    await closeTime.fill(ev.rsvpCloseTime);
    await closeTime.blur().catch(() => {}); // commit before anything reads it back
    await page.waitForTimeout(500);
    const got = await closeTime.inputValue();
    if (!got.startsWith(ev.rsvpCloseTime)) {
      throw new Error(`RSVP close read-back mismatch: wanted ${ev.rsvpCloseTime}, got ${got}`);
    }
    if (!ev.rsvpCloseSameDay) {
      rsvpNote = `set to ${ev.rsvpCloseTime} BUT it falls on the previous day — check the date by hand`;
    } else {
      rsvpNote = `closes ${ev.rsvpCloseTime} (${ev.rsvpMinutesBefore} min before start)`;
    }
  } catch (err) {
    rsvpNote = `NOT SET (${err.message}) — set "${ev.rsvpCloses}" by hand`;
  }
  log(`RSVP window: ${rsvpNote}`);

  // Include the session in the name: several sessions go to the same group in
  // one run, and a group-only name silently overwrites all but the last.
  const shot = `${group}-${ev.startIso.slice(0, 10)}-${ev.startTime.replace(':', '')}`;
  if (runDir) await page.screenshot({ path: join(runDir, `${shot}-filled.png`), fullPage: true });

  if (!save) {
    log('FILL ONLY — not saving.');
    return { saved: false, photoNote, missed, rsvpNote };
  }

  await centerAndClick(page, page.locator('[data-testid=event-save-draft-btn]'), 'Save as draft');
  await page.waitForTimeout(5000);
  if (runDir) await page.screenshot({ path: join(runDir, `${shot}-after-save.png`), fullPage: true });
  log('saved as draft');
  return { saved: true, photoNote, missed, rsvpNote };
}
