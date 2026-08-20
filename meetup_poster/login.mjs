// One-time interactive login.  Opens a real browser, waits for you to sign in,
// then saves the session to .auth/state.json so later runs skip this.
//
//   node meetup_poster/login.mjs

import { chromium } from 'playwright';
import { mkdirSync, existsSync, chmodSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const AUTH_DIR = join(HERE, '.auth');
const STATE = join(AUTH_DIR, 'state.json');
const PROBE = 'https://www.meetup.com/home/';
const WINDOW_MS = 10 * 60 * 1000;

// Logged out, Meetup bounces to /login/ OR /register/ depending on the page.
// Missing /register/ here once made this report success while signed out.
const SIGNED_OUT = /\/login\/|\/register\/|\/auth\/|accounts\.google\./;

/** Logged in iff /home/ renders instead of bouncing to a signed-out page. */
async function isLoggedIn(page) {
  await page.goto(PROBE, { waitUntil: 'domcontentloaded' });
  if (SIGNED_OUT.test(page.url())) return false;
  // Belt and braces: a real session carries more than the two anonymous
  // tracking cookies (MEETUP_BROWSER_ID, SIFT_SESSION_ID).
  const cookies = await page.context().cookies();
  return cookies.some((c) => /member|session|auth|token/i.test(c.name)
    && !/^(MEETUP_BROWSER_ID|SIFT_SESSION_ID)$/.test(c.name));
}

const browser = await chromium.launch({ headless: false, args: ['--window-size=1400,1000'] });
const context = await browser.newContext({
  storageState: existsSync(STATE) ? STATE : undefined,
  viewport: { width: 1400, height: 1000 },
});
const page = await context.newPage();

if (await isLoggedIn(page)) {
  console.log('Already logged in — session still good.');
} else {
  console.log('Not logged in. Opening the login page.');
  console.log('>>> Sign in to Meetup in the browser window. I will wait up to 10 minutes. <<<');
  await page.goto('https://www.meetup.com/login/', { waitUntil: 'domcontentloaded' });

  const deadline = Date.now() + WINDOW_MS;
  let ok = false;
  while (Date.now() < deadline) {
    await page.waitForTimeout(3000);
    // Don't navigate while they're typing; just watch where the page ends up.
    if (SIGNED_OUT.test(page.url())) continue;
    ok = await isLoggedIn(page);
    if (ok) break;
  }
  if (!ok) {
    console.error('Timed out waiting for login. Nothing saved.');
    await browser.close();
    process.exit(1);
  }
  console.log('Login detected.');
}

mkdirSync(AUTH_DIR, { recursive: true });
await context.storageState({ path: STATE });
chmodSync(STATE, 0o600);
console.log(`Saved session to ${STATE} (chmod 600).`);

const names = (await context.cookies()).map((c) => c.name).sort();
console.log(`Cookies stored: ${names.length} — ${names.join(', ')}`);

await browser.close();
