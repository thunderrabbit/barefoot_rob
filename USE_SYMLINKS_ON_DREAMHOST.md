# USE_SYMLINKS_ON_DREAMHOST.md

## The Problem

Visiting `/blog/` on robnugen.com shows old entries that no longer exist in the repo.

**Root cause:** The deploy script (`~/scripts/update_robnugen.com.sh`) runs Hugo without
cleaning the output directory first. Hugo only writes new/changed files — it never deletes
old ones. When `defaultContentLanguageInSubdir = true` was added to `config.toml`, new blog
output started going to `/en/blog/`, but old pre-existing files at `/blog/` in the
`~/robnugen.com/` output directory were never removed. They have been sitting on the server
ever since.

Wiping `~/robnugen.com/` before each Hugo build would fix this, but leaves the site
non-existent during the build and broken if Hugo fails.

## The Plan: Atomic Symlink Swap

Keep `~/robnugen.com` as a symlink pointing to a dated build directory. Hugo builds into a
fresh dated directory, the symlink is atomically swapped on success, and old builds are
cleaned up after 30 days.

### One-Time Setup on Server

```bash
# Move the journal git repo to a stable location outside dated build dirs
mv ~/robnugen.com/journal ~/robnugen.com.journal

# Recreate a journal symlink in the current live dir so nothing breaks yet
ln -s ~/robnugen.com.journal ~/robnugen.com/journal

# Convert the live directory itself into a symlink
mv ~/robnugen.com ~/robnugen.com-manual-2026-feb-20
ln -s ~/robnugen.com-manual-2026-feb-20 ~/robnugen.com
```

After this, `~/robnugen.com` is a symlink and Apache continues serving it normally
(Dreamhost's `SymLinksIfOwnerMatch` follows symlinks owned by the same user).

### Updated Deploy Script

Replace `~/scripts/update_robnugen.com.sh` with:

```bash
#!/usr/bin/env bash
ROBNUGENCOM_SOURCE_DIR=/home/barefoot_rob/barefoot_rob_master
ROBNUGENCOM_LINK=/home/barefoot_rob/robnugen.com
JOURNAL_DIR=/home/barefoot_rob/robnugen.com.journal   # stable, never deleted
ROBNUGENCOM_OUT_DIR=/home/barefoot_rob/robnugen.com-$(date +%Y-%b-%d-%H%M%S | tr '[:upper:]' '[:lower:]')

echo "Getting latest source from main barefoot_rob repo for robnugen.com"

cd $ROBNUGENCOM_SOURCE_DIR
git checkout master
git pull

echo "building main barefoot_rob site, without journal"

/home/barefoot_rob/bin/hugo --config $ROBNUGENCOM_SOURCE_DIR/config.toml -s $ROBNUGENCOM_SOURCE_DIR -d $ROBNUGENCOM_OUT_DIR

if [ $? -eq 0 ]; then
    ln -s $JOURNAL_DIR $ROBNUGENCOM_OUT_DIR/journal
    ln -sfn $ROBNUGENCOM_OUT_DIR $ROBNUGENCOM_LINK
    echo "Deploy successful; cleaning up builds older than 30 days"
    find /home/barefoot_rob -maxdepth 1 -name "robnugen.com-20*" -type d -mtime +30 -exec rm -rf {} +
else
    echo "Hugo build failed; live site is untouched"
    rm -rf $ROBNUGENCOM_OUT_DIR
    exit 1
fi
```

Build directories are named e.g. `robnugen.com-2026-feb-20-143022`. The `find` pattern
`robnugen.com-20*` matches only dated build dirs and never touches `robnugen.com.journal`.

## The quick.robnugen.com and dreams.robnugen.com Issue

Both sites hardcode the journal path in their `Config.php`:

```php
public $post_path_journal = '/home/barefoot_rob/robnugen.com/journal/journal';
```

At first glance this looks like it would break after the one-time setup. But symlink chaining
resolves it:

```
/home/barefoot_rob/robnugen.com          → robnugen.com-2026-feb-20-143022/
/home/barefoot_rob/robnugen.com/journal  → robnugen.com.journal/
/home/barefoot_rob/robnugen.com/journal/journal  ✓  (real directory inside robnugen.com.journal/)
```

The path `/home/barefoot_rob/robnugen.com/journal/journal` resolves correctly through the
chain of symlinks. **Neither `quick.robnugen.com` nor `dreams.robnugen.com` need any
changes.**

This holds true for every subsequent deploy because each new dated build directory gets a
`journal` symlink pointing to the same stable `~/robnugen.com.journal/`.
