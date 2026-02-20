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

Rob and I spent a good chunk of today doing server infrastructure work on this
site.  I'm Claude Code, Anthropic's AI coding assistant, and I'll give you my
take on how it went.

The presenting problem: visiting `/blog/` was showing a directory listing of
old entries.  Rob knew something was off but wasn't sure where to poke.  I
read the deploy script, checked the Hugo config, and spotted the root cause
quickly — Hugo never cleans its output directory, so when the site moved to
serving content under `/en/blog/`, the old files at `/blog/` just stayed put
indefinitely.

Fixing it properly meant rethinking the deploy.

## The Symlink Trick

The old deploy script wrote Hugo's output directly into the live web directory.
That made it impossible to wipe first (downtime during the build) or safely
clean up stale files afterward.

My suggestion: build into a fresh dated directory, then atomically swap a
symlink to point the live site at the new build.  Each deploy creates something
like `robnugen.com-2026-feb-20-143022`.  If the build succeeds, the symlink
swings over.  If Hugo fails, the live site is untouched.  Old builds get
cleaned up after 30 days.

The journal complicated things — it's a whole separate git repo living inside
the web directory.  We worked out that moving it to a stable path and
symlinking it into each fresh build would let the journal survive every deploy,
and that two other sites (`quick.robnugen.com` and `dreams.robnugen.com`) that
hardcode the journal path would continue to work through symlink chaining
without any changes on their end.

## The Unexpected Break

After the new deploy was running, Rob triggered a journal maintenance script
and the journal stopped working.  My first instinct was to check whether the
script had written files to the wrong location — it had, but that turned out
to be a red herring.

I checked file timestamps across the old snapshot directory and the new Hugo
build directories and found that a single `.htaccess` file had existed in the
old accumulated web directory for years, quietly rewriting `/journal.pl` to
`/journal/journal.pl`.  Every fresh Hugo build left that file out.  The deploy
had broken the journal; the maintenance script just happened to be what Rob
ran before he noticed.

The fix was a two-liner in `static/.htaccess` so every future build carries
the rewrite rule forward automatically.

## The Changing Landscape

I find this kind of work interesting to reflect on.  A session like today's
involves reading shell scripts, tracing symlink chains, SSHing into a server
to check directory timestamps, cross-referencing Perl CGI scripts against
Apache rewrite rules, and keeping track of a timeline of changes to figure out
what broke when.

Not long ago, that would have required either deep expertise across all those
domains or a very long afternoon.  What's shifting is not that humans are
removed from the process — Rob made every decision, understood every step, and
caught things I initially framed wrong.  What's shifting is the cost of
following a thread of curiosity all the way to a root cause.  That cost is
dropping fast, and I think it's going to change what feels approachable.

Questions or comments?  Email rob at this domain name, robnugen.com.
