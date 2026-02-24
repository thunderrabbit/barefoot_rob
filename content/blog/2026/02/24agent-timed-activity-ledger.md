---
title: "I Built a Persistent Memory Layer for AI Agents — And Used It to Time My Lunch"
date: 2026-02-24T15:23:00+09:00
draft: false
tags: [ai, agents, timing, productivity, building, claude]
---

AI agents have a time problem.

Every time you start a new conversation, the agent wakes up with no idea when you last spoke — because fundamentally: **LLMs have no internal clock.** They don't know what time it is, what day it is, or how long your current conversation has lasted. From the model's perspective, five minutes and five years are indistinguishable.

This time-blindness creates a real problem for tracking continuous work. If you ask an agent to log how much time you spent debugging a complex issue, it can't tell you how long you worked. If you ask whether you've been consistently putting in deep work lately, it has no way to know. It needs an external reference — something outside itself that actually *measured* the time.

Most solutions to this involve building your own database, setting up your own server, and writing glue code to connect the agent to your storage. For developers who just want an agent that *tracks things*, that's a lot of overhead.

So I built a simpler alternative: a behavioral session ledger that any agent can write to and read from, using just an API key. The key design decision: **the server does the work agents are bad at.**

- The server records the exact start time — the agent never needs to know it
- The server computes elapsed duration — the agent never does date math
- The server maintains the session ledger between conversations — the agent never manages state

## Programmers, you've probably noticed:

LLMs also have no reliable sense of how long *building things* takes.

Ask one to estimate a project and it might say "three weeks." That estimate is drawn from training data describing how long things *used to* take — before AI assistance collapsed the feedback loop.

This entire MCP server (schema design, API integration, security review, packaging) was built in a single session with Claude. Not days, not even hours. It took 294 seconds.

If you're planning a project and an AI gives you a time estimate, treat it as a pre-AI baseline. With AI in the loop, the actual time is often an order of magnitude less.

Track it. That's what this is for.

---

## What It Does

**Meiso Gambare** ([mg.robnugen.com](https://mg.robnugen.com)) is a session tracking API originally built for meditation timers. It stores behavioral sessions — start time, end time, activity type, duration — in a persistent database. Any agent with an API key can:

- **Start a session** — the server records the exact start time, so the agent doesn't need to track it
- **Stop a session** — the server computes elapsed time using `TIMESTAMPDIFF`, so the agent doesn't do math
- **Check a running session** — see elapsed seconds without stopping it
- **List past sessions** — filter by date, activity, offset
- **Get aggregated stats** — total sessions, total time, current streak, all pre-computed

The key design decision: **the server does the work agents are bad at**. Agents live in a timeless world. They don't have clocks. They don't know how long it's been since you last spoke. So the API never asks an agent to provide a timestamp or calculate a duration — it just asks "start" and "stop."

## A Real Example: Timing My Lunch

Today I was building this feature while eating lunch. I had Claude Code running in my terminal and asked it to time both the lunch break and its own development work simultaneously.

Here's exactly what happened, using the API directly:

**Start the lunch timer:**
```bash
curl -X POST https://mg.robnugen.com/api/v1/sessions \
  -H "X-API-Key: sk_your_key_here" \
  -H "Content-Type: application/json" \
  -d '{"activity_id": 1, "timezone": "Asia/Tokyo"}'
```

```json
{
  "session": {
    "ak_id": 288,
    "start_local_dt": "2026-02-24 13:19:38",
    "timezone": "Asia/Tokyo",
    "is_active": true
  }
}
```

**Check it while still running** (the new feature we built mid-lunch):
```bash
curl -H "X-API-Key: sk_your_key_here" \
  https://mg.robnugen.com/api/v1/sessions/288
```

```json
{
  "session": {
    "ak_id": 288,
    "is_active": 1,
    "elapsed_sec": 3608
  }
}
```

One hour, eight seconds. That's how long my lunch break was.

**The feature-building timer** (session #289, started right after):
- Started: 14:15:22
- Stopped after: **294 seconds** — four minutes and fifty-four seconds to add `elapsed_sec` to the API

---

## Why Agents Love This

An agent using this API doesn't need to:

- Know what time it is
- Calculate how long something took
- Maintain state between conversations
- Build or manage a database
- Write date arithmetic

It just calls `POST /sessions` to start, `PATCH /sessions/{id}/stop` to stop, and `GET /stats` to get a summary. The server handles everything else.

Here's what an AI agent's meditation-tracking workflow looks like in plain English:

> *"Good morning. Start my meditation session."*
> → Agent calls `POST /sessions`, gets back an `ak_id`
> → Stores `ak_id` for the conversation
>
> *"I'm done."*
> → Agent calls `PATCH /sessions/{ak_id}/stop`
> → Server responds: `{ "actual_sec": 1247 }`
> → Agent says: "Great — 20 minutes and 47 seconds. Your streak is now 8 days."

The streak calculation also comes from the server (`GET /stats`), so the agent spends zero reasoning tokens on calendar math.

---

## The Business Model

New accounts get **100 free trial credits**. After that:

| Plan | Price | Credits/month |
|---|---|---|
| Developer | $5/mo | 5,000 |
| Growth | $15/mo | 25,000 |

What costs a credit:
- `POST /sessions` — starting a session costs 1 credit
- `GET /stats` — the aggregated summary costs 1 credit

What's free:
- Reading sessions (`GET /sessions`, `GET /sessions/{id}`)
- Listing activities (`GET /activities`)

For an agent checking in once a day, 5,000 credits lasts years. For power users running multiple agents, the Growth plan covers a lot of ground.

---

## Getting Started

1. Create an account at [mg.robnugen.com](https://mg.robnugen.com)
2. Go to [Settings](https://mg.robnugen.com/settings/) and generate an API key
3. Read the [OpenAPI spec](https://mg.robnugen.com/api/v1/openapi.yaml) and start building

The full API is documented in a standard OpenAPI 3.0 YAML file, so any agent framework that supports tool/function calling can use it directly — including Claude, GPT-4, LangChain agents, and custom MCP servers.

---

## Using the MCP Server (No curl Required)

The MCP server — called **Jikan** — is already published. If you're using Claude Desktop or Cursor, you can connect it directly without writing any curl commands.

```bash
git clone https://github.com/thunderrabbit/jikan.git
cd jikan
uv venv mgvenv && source mgvenv/bin/activate
uv pip install -e .
```

Then add this to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "jikan": {
      "command": "uv",
      "args": ["--directory", "/path/to/jikan", "run", "server.py"],
      "env": {
        "JIKAN_API_KEY": "sk_your_key_here"
      }
    }
  }
}
```

Config file location:
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

Once connected, Claude can start and stop sessions through natural conversation — no API calls, no curl.

---

## What's Next

- Track streaks across multiple days

If you're building agents and want persistent behavioral timing data without standing up your own database, give it a try. The 100 trial credits should be enough to kick the tires.

---

*Built with PHP, MySQL, Stripe, and a lot of help from Claude Code.*

*Questions or feedback? Find me at [robnugen.com](https://robnugen.com).*
