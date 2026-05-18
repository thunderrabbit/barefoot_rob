---
title: "git close-bubble: Closing Merge Bubbles Without Thinking"
date: 2026-05-18T09:00:00+09:00
draft: false
tags: ["2026", "git", "workflow", "tools", "ai"]
---

[![git close-bubble demo](https://asciinema.org/a/WJnSLElsrfpaFgKm.svg)](https://asciinema.org/a/WJnSLElsrfpaFgKm)

#### The Merge Bubble Pattern

I like `git`.  I use it for all my programming projects of course, and everything
from `~/.ssh/`
to `~/.claude/`
to my Godot game (coming soon, I promise)
to my book formatted in LaTeX,
and nearly any directory that's got custom-edited text files in it.

I generally work alone on my projects,
so I don't need PRs like
`[github-flow](https://docs.github.com/en/get-started/using-github/github-flow)`
and especially don't need the original
`[git-flow](https://nvie.com/posts/a-successful-git-branching-model/)`.
But I do like to keep groups of commits together.  For that, I like merge bubbles.

For example:

```
*   e3f9cca DONE admin set existing user password
|\
| * 0a6dd90 Admin user_edit: hide set-password panel on self + server-side guard
| * d5dc655 AdminSetPasswordCest: end-to-end round trip on abc
| * ba74df9 placeholder for AdminSetPasswordCest
| * bbb4013 Admin user_edit: set-password form + handler
| * 384f4ba locale: admin user_edit set-password strings (EN + JA)
|/
* 7cd2527 BEGIN admin set existing user password
*   658cc93  DONE admin-driven brand manager registration
|\
| * 6e1f640 register.php: admin-driven success message names the new manager + login URL
| * bcda5fd register.php: gate to admin only post-bootstrap
| * 94b8c63 Admin users list: '+ Add brand manager' link to /login/register.php
|/
* 8eb82ba BEGIN brand manager registration UX
```

Every set of related commits lives inside a bubble.  I start with a `BEGIN` commit, which generally has either nothing (via `--allow-empty`) or a minimum change, like updoot the the version of the code.

From there, I stack up a bunch of related commits. When it's time to close the commit, I just:

1. Look up the hash of the BEGIN commit
2. Copy the hash to my paste buffer
3. `git checkout [paste]`
4. `git merge --no-ff active-branch -m "DONE with my awesome change"`
5. `gitl`, which for me means `git log --oneline --graph --decorate --all`
6. Look up the newly created hash for the DONE commit
7. Copy the hash to my paste buffer
8. `git branch -f active-branch [paste]`
9. `git checkout active-branch`

It's a lot!  It's a mess; it's annoying; it's fragile, but it's repeatable and I love it.

I asked my AI about it and it was like "yeah no worries mate" (or something like that), and presented me with this script which I have saved in `~/.local/bin/git-close-bubble`:

#### git close-bubble

```bash
#!/usr/bin/env bash
# Close a merge bubble started with a "BEGIN ..." commit.
# Usage: git close-bubble <message> [BEGIN-commit]
#        git close-bubble --dry-run [BEGIN-commit]

set -euo pipefail

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=1
    shift
fi

if [ "$DRY_RUN" -eq 0 ] && [ $# -lt 1 ]; then
    echo "usage: git close-bubble <message> [BEGIN-commit]" >&2
    echo "       git close-bubble --dry-run [BEGIN-commit]" >&2
    exit 1
fi

if [ "$DRY_RUN" -eq 1 ]; then
    MSG=""
    BEGIN_ARG="${1:-}"
else
    MSG="$1"
    BEGIN_ARG="${2:-}"
fi

B=$(git branch --show-current)

if [ -n "$BEGIN_ARG" ]; then
    S=$(git rev-parse --verify "$BEGIN_ARG")
else
    CLOSED=$(git log --merges --format='%P' | awk '{print $1}' | sort -u)
    S=""
    while IFS= read -r c; do
        if ! printf '%s\n' "$CLOSED" | grep -qx "$c"; then
            S="$c"; break
        fi
    done < <(git log --grep='^BEGIN ' --format='%H')
    if [ -z "$S" ]; then
        echo "error: no unclosed BEGIN commit found" >&2
        exit 1
    fi
fi

echo "Would close bubble starting at: $(git log -1 --format='%h %s' "$S")"

if [ "$DRY_RUN" -eq 1 ]; then
    echo "(dry-run; no changes made)"
    exit 0
fi

git checkout "$S"
git merge --no-ff "$B" -m "$MSG"
M=$(git rev-parse HEAD)
git checkout "$B"
git merge "$M"

echo "Done. Branch '$B' now points at $M. Inspect, then 'git push' when satisfied."
```

It near-magically handles the fragile command line stuff with a single line:

```bash
git close-bubble "DONE my cool code"
```

It does all the 9 steps above without me having to copy hashes and remembering all the incantations.

#### Dry Run

There is a dry-run option you can use to see what hash it would target as the BEGIN commit.

```bash
git close-bubble --dry-run
```
