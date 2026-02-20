---
title: "Debugging site deploy with AI help"
tags: [ "2026", "AI", "claude", "server", "hugo", "deploy", "symlinks" ]
author: Rob Nugen
date: 2026-02-20T20:00:00+09:00
aliases: [
    "/blog/2026/02/20debugging-site-deploy-with-ai-help",
]
---

Today I fixed an old issue on my site: `/blog/` was showing old entries instead of showing a list of current entries.
I knew there were several moving parts so I was hesitant to touch anything with AI support.

Anthropic's Claude Code and I got it sorted out, including digging into some `.htaccess` rules that I had forgotten I wrote ages ago.

Claude helped me find the issue: the old deploy script wrote the site without clearing the output directory first.
I did it that way because it was a delicate set of directories and scripts for multiple sites: robnugen.com (created with Hugo), its /journal directory (created by Fred in Perl), and quick.robnugen.com, and dreams.robnugen.com written in PHP. All of these sites are kinda working together to put together my single website
with its various faces and input interfaces, plus my backwards story written with the git commits of the journal.

With Claude Code I was able to clean it all up today. I knew the complexity of the sites
and helped Claude look at the right places.  With Claude's ability to deal with the syntax of `.htaccess` and `ln` parameters, we got it all working relatively easily.

Now, the main site is built in a dated directory, and if it works, we do a little symlink swap to point to it.

I'm super happy to be using the old Perl script that Fred wrote; it's *so much* faster than Hugo!
Plus it has the calendar on the left hand side for navigation.

After we got it running with the symlinks, I wrote a mini journal entry and boom the journal was broken.
Ugh. Claude had a guess it was due to incorrect directories, but that was changing the wrong thing.
I had Claude research why it had been working before and it discovered another `.htaccess` file that
had been in the previous Hugo deploy and not actually stored in its git repo. Oops!

Claude says:

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
