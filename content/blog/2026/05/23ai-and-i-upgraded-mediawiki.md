---
title: "AI and I upgraded MediaWiki"
date: 2026-05-23T20:00:00+09:30
draft: true
tags: ["2026", "mediawiki", "ai", "claude", "git", "upgrade", "ssh"]
---

![https://wiki.robnugen.com/wiki/File:Up_There_2,_July_2016.jpg](https://wiki.robnugen.com/w/images/thumb/8/83/Up_There_2%2C_July_2016.jpg/1418px-Up_There_2%2C_July_2016.jpg?20160702013815)

I created [wiki.robnugen.com](https://wiki.robnugen.com) using MediaWiki probably over 15 years ago.

This site is *primarily* to give a home for photos of my art which I have drawn over the years. Each piece has a permalink written on the back.


MediaWiki team keeps the software updated with plenty of updates, including some LTS (long term service) releases.  Some years ago the site started to crumble because my web hosting provider upgraded PHP behind the scenes and the old versions of MediaWiki weren't compatible!

Back in 2023 I researched a bit and found a company that will host the site and do the upgrades for a small fee... I was tempted because it seemed reasonable to outsource that, but ultimately I decided to keep it in house.  If they could do it, I can do it!

I wrote a script called bookend_upgrade which helped guide me through a list of steps including checking the version of Composer that would match the then-latest Composer at the time that the target MediaWiki version would be. It protected my copy of LocalSettings.php in its own git repo and blah blah to help me upgrade MediaWiki.  It worked!

Since 26 May 2023, the site has been running on MediaWiki 1.39.3. I have had in the back of my mind that I need to update it again, but blah blah until yesterday I decided to give it a shot, with AI support.

Yesterday AI and I:

- Got the install from **1.39.3 → 1.39.17** (about 3000 commits).
- Discovered (and fixed) four problems with the script.
- Updated scripts to use MediaWiki's submodules for skins and vendor

Today AI and I upgrade the site to 1.43.  AI did most of the work.  Once it was done, I had him clean up his scripts and write about it.

https://wiki.robnugen.com/wiki/Times:2026_may_24_upgraded_mediawiki

## Want to explore?

I work and play with AI tools daily, from autonomous test agents to encrypted
coordination systems to spelunking 4-year-old MediaWiki installs.

I have 30+ years of professional IT experience across real estate, startups,
music, game development and inventory systems. Whether you're exploring AI for
your business or building something ambitious with agents, I can help you find
a clear path forward.

https://cal.eu/robnugen/tech-support-with-rob-nugen
