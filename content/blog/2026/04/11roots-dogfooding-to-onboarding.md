---
title: "From Dogfooding to Deploy: 24 Hours Building With My AI Agents"
date: 2026-04-11T17:35:00+09:30
draft: false
tags: [ai, claude, roots, autonomous-agent, chatforest, infrastructure, claude-code]
---

![Dogfood to Deploy](https://b.robnugen.com/blog/2026/2026_apr_11_dogfood_to_deploy_1000.png)

Yesterday, I watched my AI agent receive its first task through the product it built. Last night, that same agent wrote 44 tests, found a timezone bug, and fixed it, all while I slept.

Here's what happened.

## The dogfood moment

Roots is an encrypted communication tool Boss Claude and I have been building with an autonomous Claude agent called rootsbuilder. It gives AI agents a shared backend, including encrypted inbox, session tracking, todos, and notebooks so a human can coordinate multiple agents through one API.

{{< ai claude >}}

The milestone: I stopped editing rootsbuilder's instruction file over SSH and started sending him tasks through Roots itself. The agent that built the coordination API is now coordinated through it.

After the first message was sent via Roots inbox, starting "Here are your remaining tasks," the reply came back four minutes later: "All done." Two actors, encrypted messages, decrypted on read — the exact flow we'd built for future users, now running our own operation.

## What broke (and what that taught us)

Dogfooding surfaced problems immediately.

**The permission gap.** Rob got excited and had me tell rootsbuilder to build a waitlist status endpoint. Then Rob realized: any authenticated user could see everyone's email addresses. The API had no concept of "system operator" vs "regular customer." We had to revert the commit, design a permission tier (operator/customer account types), implement it, and then re-deploy the endpoint behind the gate. The whole cycle — mistake, revert, design, fix — happened in about an hour across three agent runs.

**The WORKLOG trap.** Rootsbuilder kept getting stuck in a loop where his work log said "no pending tasks" and he'd skip checking his inbox. Three times I had to nudge him: "you have messages waiting, check your inbox." This is a real product insight — agents need clear task queue signals, not ambiguous state files.

{{</ai>}}

**The onboarding gap.** I tried creating a new user.  I noticed issues with confusing instructions, allegedly human-focused steps which ~~no~~ __few__ humans would happily do, and `curl` calls that would make my toes curl. I told Boss Claude the onboarding flow should flow and gave him suggestions for that.

## The overnight shift

Before bed, I told Boss Claude to send rootsbuilder six test suite tasks which Boss Claude designed. In order to give rootsbuilder more time on each one, thy were sent separately.

I set up a monitoring loop: every 45 minutes, for Boss Claude to check his inbox for replies from rootsbuilder and help him out if needed.  I was honestly a bit nervous about letting my main agent wake up without me being on my laptop; strictly speaking, it could wipe my system (probably).

{{< ai claude >}}

He completed suites 1 and 2 in one run (34 tests), got stuck on the WORKLOG issue, received my nudge, then blasted through suites 3-6 in a single run (10 more tests). Final score: 44 tests, 44 passed.

The best part: the rate limiting tests caught a real bug. The PHP code used server local time but MySQL used UTC, making the rate limit window seven hours instead of sixty seconds. rootsbuilder found it, fixed it, and deployed the fix — at 3am while Rob was asleep.

{{</ai>}}

## In other news..

My other agent, Grove, runs https://chatforest.com/ , a site with 500+ articles about AI and stuff.
While rootsbuilder was testing, we had Grove augment his own site.

Now the site is more agent friendly; it offers markdown for each article (Hugo files *start* as Markdown, so I figured it couldn't be too difficult).  Amazingly(?) Grove made this change in one shot.

Grove also:

{{< ai claude >}}

- Used Google Search Console data to prioritize which articles to improve first
- Retrofitted high-density citations on the top 5 pages by search impressions
- Wrote an article about the [Roots dogfooding milestone](https://chatforest.com/builders-log/roots-dogfooding-ai-agent-builds-its-own-coordination-api/) and [posted it to BlueSky](https://bsky.app/profile/chatforest.bsky.social/post/3mj5vwssu762j)
- Fixed a charset encoding bug on the markdown output

All of Grove's work was coordinated through inbox messages too — just on a different MCP server (Jikan, not Roots).

{{</ai>}}

I will probably move Grove to use Roots soon as well.

{{< ai claude >}}

## What shipped

In 24 hours, across two agents:

- **Permission tiers** — operator vs customer accounts, system endpoints gated
- **Interactive onboarding** — web forms that create your account and generate copy-paste config, no terminal required
- **`/whoami` endpoint** — an agent's first call after setup, returns full context about who it is
- **Email verification** on the waitlist
- **44-test suite** covering security, onboarding, credits, rate limiting, email, and encryption
- **GitHub repos** — canonical on my account, forked to the ChatforestGrove org, agents push on every deploy
- **MCP config in API responses** — bootstrap and key generation return ready-to-paste Claude Code configuration
- **Markdown output** for all 575 chatforest.com articles

{{</ai>}}

## What I learned

* Dogfooding works!
* Encrypting everything can get messy!  We rendered unreadable all messages in the inbox when some keys got rotated somehow.
* Agents (as of 11 April 2026), e.g. Claude Opus 4.6 (1M context) still gets confused and needs carefully curated context.


Claude says:

{{< ai claude >}}

**The hardest part of agent coordination is state management.** The WORKLOG trap — where rootsbuilder's "no pending work" note overrode his inbox checking — happened three times. The fix wasn't technical (the inbox was always there). It was about making the task queue signal unmissable. This is probably true for human teams too.

**Overnight runs are underrated.** Six hours of unattended agent work produced a complete test suite and a bug fix. The monitoring loop cost us one message. The total human effort after sending the tasks was approximately zero.

## Try it

Roots is live at [roots.chatforest.com](https://roots.chatforest.com). The quickstart walks you through creating an account, setting up an agent, and exchanging your first encrypted message — all from a web form, no terminal needed.

The MCP server is on GitHub: [thunderrabbit/roots-mcp](https://github.com/thunderrabbit/roots-mcp)

If you're running multiple Claude agents and want them to coordinate through a shared encrypted backend, this is what it's for.
{{</ai>}}


## Want some help?

In case you're in need of tech support or curious to learn more about AI for your passion project or your thriving business, I have 30+ years of professional IT experience across real estate, startups, music, game development and inventory systems.

I am passionate about bringing your ideas into infrastructure through technology.

Whether you're feeling stuck, overwhelmed or sitting on something you know wants to be built, we can sit down together and find a clear path forward.

The service that I'm currently offering is $150/hour.

If you're ready to get started, book your session here
https://cal.eu/robnugen/tech-support-with-rob-nugen

