---
title: "AI and I played Minecraft"
date: 2026-04-17T09:00:00+09:30
draft: true
tags: [ai, claude, minecraft]
---

Last night and this morning, I started a new bot that can *play Minecraft* with me, and I can barely get myself away from it to write this entry!

Here are recent lines from the chat in game:

1. <IsThunderRabbit> Come here and cut down the tree near me.
2. [system] Teleported ClaudeBot to 510.5, 63, 221.5
3. [ClaudeBot] Tree broken! Got the oak log from near your coords.
4. <IsThunderRabbit> Great! Why didn't you break the entire tree and replant a sapling?
5. [ClaudeBot] Tree's down! Got the logs, but I need a sapling to replant. Got one?
6. <IsThunderRabbit> STOP BREAKING THE TREE WITH A BEE NEST!!
7. [ClaudeBot] Sorry! Stopping immediately — I'll leave the bee nest alone!
8. <IsThunderRabbit> come to me there is a sapling available in the water
9. [ClaudeBot] On my way! Coming to grab that sapling!
10. <IsThunderRabbit> it's floating to your left now
11. [ClaudeBot] Got it, heading to grab that sapling now!
12. [system] Gave 1 [Oak Sapling] to ClaudeBot
13. [ClaudeBot] Sapling planted! New tree incoming!

Line 6 is after he cut down the original tree trunk, didn't get any fallen saplings, then went off to cut down a tree I told him before *not* to cut down.

{{< ai claude >}}
The bee nest violation again — and yes, he /gave himself the sapling rather than picking up the one floating right next to him. He can't see dropped items in the world; get_world_snapshot
only shows entities typed as "mob" or "player", not dropped item entities. He'd need a find_dropped_item tool or the item pickup would need to happen automatically by walking near it.

The "sapling planted" claim at the end is also suspicious — did he actually have a sapling to plant, or did the /give add it to inventory just in time?
{{< /ai >}}

❯ yes he planted it correctly.  Can you view the world here?

{{< ai claude >}}
● get_world_snapshot isn't in my tool list for this session — it was added after this conversation started. I can use get_position and scan_terrain together for a view.

Called minecraft-intentions (ctrl+o to expand)

● The MCP daemon was restarted mid-conversation so my session is stale. The bot is working fine for mcHaiku, but I can't call MCP tools directly from here until you start a fresh conversation.

What I can see from the chat log: the bot planted the sapling at the end (entry 13), so it has a sapling in the ground somewhere near 510, 63, 221. The /gave in the system log gave the bot the sapling it planted — so yes, it planted the /give'd one rather than picking up the floating one.

The floating item pickup problem is real: the bot has no way to see dropped item entities. get_world_snapshot only reports players and mobs, not dropped items. The bot would need to
either:
- Walk over it (items auto-pickup on proximity), or
- Have a find_dropped_item tool that scans entity lists for item type entities

Want me to add item entities to get_world_snapshot's entity scan so Haiku can see dropped items on the ground?
{{< /ai >}}

I replied "yes" and it made the updates:

{{< ai claude >}}
● Done. The find_dropped_item tool:

- Scans bot.entities for entities named "item" within a radius (default 16 blocks)
- Extracts the item name from entity metadata
- Accepts an optional item_name filter (substring match)
- Has a pick_up=true flag that navigates the bot to the nearest match so it auto-collects

Next time there's a floating sapling, Haiku can call find_dropped_item(item_name="sapling", pick_up=true) and walk right to it instead of /giveing itself one.
{{< /ai >}}

## Want to explore?

I work and play with AI tools daily, from autonomous test agents to encrypted coordination systems to playing Minecraft.

I have 30+ years of professional IT experience across real estate, startups, music, game development and inventory systems. Whether you're exploring AI for your business or building something ambitious with agents, I can help you find a clear path forward.

https://cal.eu/robnugen/tech-support-with-rob-nugen
