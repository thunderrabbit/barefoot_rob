---
title: "Debugging My Deploy with AI Help"
tags: [ "2026", "AI", "claude", "server", "hugo", "deploy", "symlinks" ]
author: Rob Nugen
date: 2026-02-20T20:00:00+09:00
aliases: [
    "/blog/2026/02/20debugging-my-deploy-with-ai-help",
]
---

Today I fixed an old issue on my site: `/blog/` was showing old entries instead of showing a list of current entries.
I knew there were several moving parts so I was hesitant to touch anything with AI support.

Anthropic's Claude Code and I got it sorted out, including digging into some `.htaccess` rules that I had forgotten I wrote ages ago.

Above is what I wrote about it.  Below is Claude's take on it:

I spent a good chunk of today doing server infrastructure work on this site,
with Claude Code (Anthropic's AI coding assistant) helping me track down some
problems I'd been vaguely aware of for a while.

The first one: visiting `/blog/` on this site used to show a directory listing
of old entries that no longer exist in my repo.  It turned out Hugo (the
software that builds this site) never cleans its output directory — it only
adds or updates files, never removes them.  So when I changed my config to
serve content under `/en/blog/` instead of `/blog/`, the old files just sat
there forever.

Fixing this properly meant rethinking my deploy script.

## The Symlink Trick

The old deploy script ran Hugo and wrote directly into the live web directory.
That meant I couldn't wipe the directory first (the site would be gone while
Hugo builds) and I couldn't safely clean up old files either.

The fix: build into a fresh dated directory, then atomically swap a symlink
to point the live site at the new build.  Each deploy creates a directory
named something like `robnugen.com-2026-feb-20-143022`.  If the build
succeeds, the symlink swings over.  If it fails, the live site is untouched.
Old builds get cleaned up after 30 days.

Getting the journal to keep working through the swap required some extra care —
the journal is a whole separate git repo that lives inside the web directory.
We moved it to a stable location and symlink it into each fresh build.

## The Unexpected Break

Once the new deploy was running, I triggered a journal maintenance script
and suddenly the journal stopped working.  Turned out the script didn't
break anything — the deploy had already quietly broken the journal by leaving
out an `.htaccess` file that had been sitting in the old web directory for
years, doing quiet rewrite-rule work nobody had noticed.

Claude traced it back by checking which files existed in the old directory vs.
the new Hugo builds, found the `.htaccess` with one key rewrite rule, and the
fix was to add it to the Hugo `static/` folder so every build carries it
forward automatically.

## The Changing Landscape

What struck me today was how different this kind of work feels now.

I'm not a server administrator by trade.  I know enough to get into trouble
and (usually) enough to get out of it.  In the past, a day like this would
have meant hours of Stack Overflow tabs, trial and error, and probably a
panicked message to a more technical friend.

Instead I had a conversation.  I described what I was seeing, Claude read the
scripts and config files, formed hypotheses, checked them against the actual
server state via SSH, and explained the root cause clearly each time.  Not
guessing — actually following the chain of symlinks and file timestamps to
find where things diverged.

I still had to understand what was happening.  I still made the decisions.
But the gap between "I notice something is wrong" and "I understand exactly
why and know how to fix it" collapsed from hours to minutes.

That's the shift.  Not that AI writes code for you, but that it shrinks the
distance between curiosity and understanding.

Questions or comments?  Email rob at this domain name, robnugen.com.
