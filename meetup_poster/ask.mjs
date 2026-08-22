// One question-asker that works both at a terminal and from a pipe/here-doc.
//
// readline alone cannot do the piped case: its line events fire before
// question() registers, so the answers vanish.  When stdin is not a TTY we
// slurp it up front and serve the answers from a queue instead.

import { createInterface } from 'node:readline/promises';

export async function createAsk() {
  let rl = null;
  let queued = null;

  if (process.stdin.isTTY) {
    rl = createInterface({ input: process.stdin, output: process.stdout });
  } else {
    const chunks = [];
    for await (const c of process.stdin) chunks.push(c);
    queued = Buffer.concat(chunks).toString('utf8').split('\n');
    if (queued.length && queued[queued.length - 1] === '') queued.pop();
  }

  const ask = async (q) => {
    if (rl) return rl.question(q);
    if (!queued.length) {
      console.error(`\n${q}\n  (no more piped input -- stopping)`);
      process.exit(1);
    }
    const a = queued.shift();
    console.log(`${q}${a}`);
    return a;
  };
  const close = () => rl?.close();

  return { ask, close };
}

/** "1 3" -> the 1st and 3rd of `items`; empty answer -> all of them. */
export function pickFrom(items, answer, { emptyMeansAll = false } = {}) {
  const t = answer.trim();
  if (!t) return emptyMeansAll ? [...items] : [];
  return t.split(/\s+/).map((n) => items[+n - 1]).filter(Boolean);
}
