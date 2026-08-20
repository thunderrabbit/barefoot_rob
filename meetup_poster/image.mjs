// Resolve the photo a .meetup.txt asks for to a local file Playwright can upload.
//
// The file names a canonical URL (…/life_is_calling_1000.png) but a hand-placed
// cache file is usually the bigger original (life_is_calling.png).  Match on the
// stem with size/variant suffixes shaved off, so either name finds the other.

import { readdirSync, statSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { join, basename } from 'node:path';

const IMAGE_EXT = /\.(png|jpe?g|webp|gif)$/i;

// Suffixes that mark a size or variant rather than a different picture.
const VARIANT_SUFFIX = /[-_](?:\d{2,5}(?:x\d{2,5})?|thumb|thumbs|small|medium|large|orig|original|full|hires)$/i;

/** Normalize a filename or URL to a comparison stem: life_is_calling_1000.png -> life_is_calling */
export function imageStem(nameOrUrl) {
  const base = basename(nameOrUrl.split('?')[0].split('#')[0]);
  let stem = base.replace(IMAGE_EXT, '');
  // Shave repeatedly: "photo_original_1920" -> "photo"
  let prev;
  do {
    prev = stem;
    stem = stem.replace(VARIANT_SUFFIX, '');
  } while (stem !== prev && stem.length > 0);
  return stem.toLowerCase();
}

/**
 * Find the best local file for `imageUrl`, downloading it only if the cache has
 * nothing matching.  When several variants match, the largest wins — Meetup
 * downscales for us, so more pixels is strictly better.
 */
export async function resolveImage(imageUrl, cacheDir, { download = true } = {}) {
  if (!existsSync(cacheDir)) mkdirSync(cacheDir, { recursive: true });

  const want = imageStem(imageUrl);
  const matches = readdirSync(cacheDir)
    .filter((f) => IMAGE_EXT.test(f))
    .filter((f) => imageStem(f) === want)
    .map((f) => ({ file: join(cacheDir, f), bytes: statSync(join(cacheDir, f)).size }))
    .sort((a, b) => b.bytes - a.bytes);

  if (matches.length) {
    return {
      path: matches[0].file,
      bytes: matches[0].bytes,
      source: 'cache',
      alternatives: matches.slice(1).map((m) => m.file),
    };
  }

  if (!download) {
    throw new Error(`No cached image matching "${want}" in ${cacheDir}, and download is off.`);
  }

  const res = await fetch(imageUrl);
  if (!res.ok) throw new Error(`Fetching ${imageUrl} failed: HTTP ${res.status}`);
  const bytes = Buffer.from(await res.arrayBuffer());
  const dest = join(cacheDir, basename(imageUrl.split('?')[0]));
  writeFileSync(dest, bytes);
  return { path: dest, bytes: bytes.length, source: 'downloaded', alternatives: [] };
}
