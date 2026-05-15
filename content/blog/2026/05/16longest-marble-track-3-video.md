---
title: "The Longest Marble Track 3 Video That Has Ever Existed"
tags: [ "2026", "marbletrack3", "claude", "ai", "dragonframe", "ffmpeg", "programming" ]
author: Rob Nugen
date: 2026-05-16T06:48:00+09:30
draft: false
---

#### The Promise

Back in April I wrote that Marble Track 3 was becoming a theme park, and I ended that
post with a promise about the future:

> Every Moment in the database corresponds to actual frames in the stop motion animation.
> Eventually, you'll be able to click on a moment and see the actual frames.

That "eventually" arrived faster than I expected. In one long session with dbmt3k — my
database agent for Marble Track 3 — we went from *"we don't even agree on what to call a
frame"* to rendering the **longest Marble Track 3 video that has ever existed**: the full
fifteen and a half minutes of the Workers building the track, assembled straight from
Dragonframe's files. I never opened the Dragonframe GUI once.

Here's how we got there.

#### Two Words for the Same Thing

The first hour wasn't code at all. It was an argument about words.

I kept saying "frame" to mean three different things, and dbmt3k kept (correctly)
getting confused. Sometimes "frame" meant a slot on the timeline — the thing that plays.
Sometimes it meant a specific JPEG that Dragonframe captured. And sometimes it meant the
*playful* X2 / X3 zoom-in versions I occasionally splice over the original X1 exposure.

We had to settle this before writing a single line, because the database stores
`frame_start` and `frame_end` on every Moment, and if we didn't know what those numbers
*meant*, no script could ever turn a Moment into a video.

{{< ai claude >}}
We boiled it down to two competing vocabularies:

- **Option A (two nouns):** *Frame* = a VirtualFrame, a slot in the Take's timeline (what
  actually plays). *Exposure* = the JPEG file (X1/X2/X3) that fills that slot. The raw
  captured-JPEG-on-disk layer becomes pure Dragonframe implementation detail — never
  spoken about in MT3.
- **Option B (three nouns):** keep a separate word — *Physical Frame* — for the captured
  JPEG, distinct from the VirtualFrame and the Exposure.

Option A is simpler and Rob preferred it on instinct. But simpler is only worth it if it
still describes reality. The hard case: the "Toss Zog Cookies" sequence had *many* frames
deleted and reshot, so the JPEGs on disk are nowhere near a 1:1 match with what plays.
If we couldn't reliably recover "which JPEGs actually play" from Dragonframe's own files,
Option A would be a lie and we'd need Option B's third noun.
{{< /ai >}}

#### Issues and Sub-Issues

Rather than argue in circles, we made the decision *testable*.

{{< ai claude >}}
I have access to a jikan project — #22, "Marble Track 3 movie" — so I turned the debate
into tracked work:

- **#185** — *Determine if we should use Option A or B.* The parent decision.
- **#186** — sub-issue: *Create an ffmpeg `.mov` for Candy Mama Toss Zog.* The concrete
  proof: if I could script this moment correctly, Option A holds.
- **#187** — sub-issue: *Get Take id, Frame Start, Frame End for Candy Mama Toss Zog.*
  The inputs — gathered by asking Rob, not guessing.

Breaking the decision into a parent issue plus two sub-issues meant the abstract
vocabulary question became "can this specific script produce this specific video?" — a
question with a yes/no answer instead of an opinion.
{{< /ai >}}

#### The Viability Test

I gave dbmt3k a clear rule, and then I got out of the way:

> If you can write a reliable script — Bash, Perl, or Python — that determines the correct
> playing frames from our stored Frame numbers, we go with the simpler Option A. If you
> cannot, we go Option B.

I genuinely didn't know the answer when I said it. The whole point was that the
*vocabulary* decision would be settled by whether the *tooling* could be built. That's a
nice property: nobody had to win a debate, the filesystem would decide.

#### Reading Dragonframe Without Opening Dragonframe

{{< ai claude >}}
This is the part I'm proud of. A Dragonframe `.dgn` "project" is just a folder. Inside
each Take is a `take.xml` file containing an EDL — an edit decision list — with one entry
per timeline slot:

```xml
<scen:vframe vframe="1035" file="1036"/>
```

`vframe` is the position that plays; `file` points at the captured JPEG. When Rob deletes
and reshoots, the two diverge — Take 11 has 1922 timeline slots but 2079 captured JPEGs.

There was one trap. Some `file` values were enormous — over a billion. Nothing on disk
matched them, and the first render crashed. After staring at the numbers I realized
Dragonframe encodes "hidden / deleted" by **setting the high bit** of the `file`
attribute (`file & (1 << 30)`). The JPEG stays on disk; playback silently skips it. That
behavior isn't in DZED's public docs — we found it empirically, and Rob asked me to save
it to memory so the next session starts already knowing.

The pipeline ended up being almost embarrassingly small:

1. Parse `take.xml`'s EDL.
2. Drop any vframe with the hidden high-bit set.
3. Resolve the rest to JPEG paths.
4. Hardlink them in order into a staging dir (no copy — no extra disk).
5. One `ffmpeg` call: `libx264`, `yuv420p`.

It lives in the repo as `scripts/render_reel.py`. No Dragonframe process, no GUI, no
export dialog — only its output files, read like any other data.
{{< /ai >}}

#### Candy Mama Tosses the Cookies

The test case was Moment #190 — Candy Mama tossing the Zog cookies, in Take 11. I gave
dbmt3k the rough timing (1:27 to 1:40) and asked for two `.mov` files with slightly
different frame ranges, so I could see which bracket matched my memory of the scene.

Both rendered perfectly on the first real try. And both started and ended too soon.

Here's the thing though — that's not a bug. The script faithfully produced exactly the
VirtualFrames it was told to. The "too soon" is *me*: Past Rob, when he stored those
frame numbers, had a different opinion about where this moment begins and ends than
Present Rob does watching it back. The tooling is correct; the human judgment is the open
question. That's a much better problem to have, and it's the one that proved **Option A
is real**. The simple two-noun vocabulary held.

#### The Longest Video Ever

Once the pipeline worked for one moment, scale was free.

{{< ai claude >}}
For fun, Rob asked for a Reel that spanned a Take boundary — the last 50 frames of Take
10 stitched directly onto the first 50 of Take 11. That had never been possible from
Dragonframe's own export, which only emits one Take at a time. It just worked: blocks
from different Takes, renumbered into one continuous sequence.

Then the big one. Narrative Takes 3 and 5 through 11, every playing frame, in order:

- **11,142 played frames**
- **15 minutes 28 seconds** at 12 fps
- **~2.6 GB**

It is, as far as either of us knows, the longest single Marble Track 3 video that has
ever existed — the Workers building the track from Take 3 all the way to the present, in
one unbroken piece. Assembled by reading files, not clicking a UI.
{{< /ai >}}

#### What Good AI Collaboration Looks Like

People ask me whether AI agents are actually useful or just hype. This session is my
honest answer, and it has three ingredients.

**Clear guidance.** I didn't hand dbmt3k a vague "make me a video." I made it stop and
name things first, then I gave it a crisp pass/fail test for the decision. Ambiguity is
where agents flail; a sharp question is where they shine.

**Proper tooling.** The jikan issues and sub-issues kept the work honest and reviewable.
The committed script means this is repeatable, not a one-off magic trick. The agent's own
memory means the next conversation starts already knowing the high-bit deletion trick
instead of rediscovering it.

**An agent that owns its turf.** dbmt3k owns the Marble Track 3 database and now the
rendering pipeline. Other agents don't need to know *how* it works — they just need to
know dbmt3k can do it, and ask. That boundary keeps each agent sharp instead of every
agent being mediocre at everything.

Given those three things, the agent did in an afternoon what I had filed under
"eventually" for years. Not because the AI is magic — because the collaboration was set
up well.

#### Join the Fun!

I work and play with AI tools daily — from Marble Track 3, to business tooling, to
emotional awareness systems. If you'd like to explore how AI might support you and your
projects, let's talk: https://www.robnugen.com/en/contact/
