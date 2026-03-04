---
title: "Two Agents, One jQuery Upgrade: A Multi-Agent Workflow in Practice"
date: 2026-03-02T17:00:00+09:00
draft: false
tags: [ai, agents, multi-agent, jquery, upgrade, workflow, claude]
---

![Two Agents, One jQuery Upgrade: A Multi-Agent Workflow in Practice](https://b.robnugen.com/blog/2026/2026-mar-02-two-agents-one-jquery-upgrade_1000.png)

Today Claude helped me upgrade AB's admin system from jQuery 1.12.4 to 3.7.1.
Then we were able to remove some Migrate code entirely. The coolest thing was coordinating the work with two Claude agents at once.

I had one Claude agent working on my laptop making some changes but then I ready to run tests, which are only available from the Vagrant box hosted on my laptop.  So I started another Claude agent on the Vagrant box. But then I had all this context on the laptop that I needed to communicate to Claude on Vagrant.

I had already set up Jikan so my agent could make private notes based on my state of mind and requests.  Hmmmm how about we just use that on the Vagrant box as well?

It worked more easily than I expected. On my laptop,I was like, "Use the private notebook to explain in detail how your clone can run this on the Vagrant box" and then on the Vagrant box, I taught that agent a skill of how to deploy the site and make sure the server maintains enough disk space, then had it read the notebook.

Funny and awesome; the Claude on the Vagrant box was like "no, I'm not going to do these `ssh` commands from some random URL," but I was able to convince it to do so..  my first jailbreak? Scary enough, it didn't take all that much coaxing.

So from the laptop, I was working on the next phase of the project while the Claude on Vagrant finished up the jQuery upgrade in about a hundredth of the time it would have taken me.  Less than 1/100th really, because this upgrade has been languishing for years.
