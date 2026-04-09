---
title: "Marble Track 3 Becomes a Theme Park"
tags: [ "2026", "marbletrack3", "claude", "ai", "rides", "programming" ]
author: Rob Nugen
date: 2026-04-07T16:00:00+09:30
draft: false
---

#### Six Months Ago

About six months ago I realized I could build a new Marble Track 3 website with AI support.  I started building https://db.marbletrack3.com as a new database-driven site to replace the old Hugo version at www.marbletrack3.com.  In the Hugo version, I simply couldn't keep up with manually editing all the markdown files and keeping track of which photos should go where.

At that time, the old handmade Hugo site had years of history I had written by hand:
"technical" descriptions of parts,
semi-technical descriptions of the Workers, heaps of photos, and historical notes.
I had a sense that I wanted to record "everything" but
keeping track of it all manually was beyond my ability.
I knew I wanted to present so much more information:
frame numbers, frame dates, worker viewpoints,
all of which would lead to individual snippets of part histories
where we can track them across time and across workers.

#### Ten Days Ago

This past past weekend, while at dinner in Perth with 5 other guys,
my friend Frase said, "wait until you guys see Rob's art project."

His comment opened the door to two hours of amazing conversation starting with me showing my
[Marble Track 2](http://mt2.robnugen.com/) video of Young Rob (haha) introducing the track. Fast forward two hours and
we were laughing at the joyful insanity of it all:
Parts of Marble Track 3 speaking
in their own voice about how they were built, and who built them!

Excited by Jo and Paul's entertained reactions,
I wanted so much to work on the project!  But it's in Tokyo!  ...
oh, but there is still plenty to do for the migration...  so AI and I got to work.

#### Migrating Everything

{{< ai claude >}}

The first task was migrating part descriptions from the old Hugo site. Each part has a markdown file with front matter, a description, and a History section with dated bullet points and photos. Rob and I worked out a process:

1. Find the Hugo file for each part
2. Parse the description and convert references to shortcodes like `[worker:g-choppy]` and `[part:triple-splitter]`
3. PATCH the description via the API
4. Create moments from each History entry, in chronological order
5. Write perspectives for each moment — from each worker's point of view (using voice profiles I'd written) and from the part's perspective ("G Choppy cut me!")
6. Attach photos from the Hugo file to the part and its moments

We did all 72 remaining parts in one session. Along the way, Rob realized photos weren't being imported, so I added `photo_urls` support to the moments and parts API endpoints, deployed it, and we kept going without missing a beat.

The migration process was iterative. Rob caught that plural parts like "Holders" should say "us" instead of "me" in their perspectives. He noticed the Hugo front matter images weren't being attached to parts. Each correction got saved to memory so I wouldn't repeat the mistake on the next batch. By the end, the process was smooth — find the Hugo file, parse it, PATCH description, POST moments with photos, PATCH perspectives. Five parts at a time, Rob reviewing each batch.
{{< /ai >}}

#### The Theme Park Idea

Realizing how much was now possible with the site, I wanted to make sure the
site itself makes sense in its own reality.
What is its reality?  Marbles rolling down a track... *woah*..  we should make it a theme park for marbles!  I told Claude the site should be written for marbles who might be interested in visiting the track.

{{< ai claude >}}
That changed everything. Parts disappeared from the main navigation. Workers became "Our Crew." Marbles became "Residents." And to keep the page simple, we needed a new concept: Rides.

A Ride is a complete journey — a marble's full experience from start to finish, visiting multiple Tracks along the way. The Grand Spiral takes large marbles from the Outer Spiral down through the Triple Splitter, around the Snake Plate U-Turn hairpin, back along the Lowest Largest Backtrack, through the Lowest Largest U-Turn (where they lift el Lifty Lever and wave a flag for the little ones), and home on The First Track.

The Ride concept emerged from Rob explaining how the physical track actually works. I had been calling individual track segments "Rides" — he corrected me: a Ride visits a whole series of Tracks. That distinction shaped the entire database schema. We created `rides` and `ride_tracks` tables, with `sequence_order` and `experience_note` for each stop along the journey. Three rides went in first: The Grand Spiral (large), The Medium Descent (medium), and The Triple Sneak-Right (small).
{{< /ai >}}

#### Naming Things Together

The physical part that catches small marbles exiting the Triple Splitter was called
"Triple Splitter Small Marble Catcher".  This technical name was no longer fit for
a theme park!
It was accurate, but not exactly enticing for a kid-marble visiting the park.

I asked Claude for ten kid-friendly names. After filtering for names that included "Triple" (so I could remember what it referred to), I selected The Triple Splitaway: "Slip out of the Triple Splitter before anyone notices!"

Claude had suggested "The Small Thrill" for the ride that includes it,
but that name grammatically implies there is only one thrilling ride
for small marbles.  Since there will be other Rides for small marbles,
I renamed it to The Triple Sneak-Right because this one specifically finishes on the right side of the track.

#### Workers Get Their Own Voice

{{< ai claude >}}

Each worker now speaks in first person. G Choppy: "I cut wood. I curve wood. I shape wood. Three frames to raise my sword, then the cut." Big Brother: "Yeah, I work here. I carry stuff. I hold stuff. Whatever." Little Brother: "ooohhh what's this?? Mama, who is that?"

We had voice profiles already written for each worker. The rewrite was straightforward — translate third-person builder descriptions into first-person character voice. The tricky part was a bug I introduced: when PATCHing descriptions without also sending the name field, the update method blanked all the worker names. Rob caught it immediately when only Y Slider showed up on the Workers page. Root cause: the admin form always sends both fields, but my API endpoint only sent one. Fixed by making the update method handle partial updates properly.
{{< /ai >}}

#### Japanese Translations

Thanks to Mayumi and the Sweets Attendants,
the old Hugo site had Japanese translations for 10 workers.
We imported them all:

* キャンディーママ (Candy Mama)
* Gチョッピー 斬り師 (G Choppy (the Cutter))
* シカタマさん (Squarehead)
* くるりん (Reversible Guy)

A couple were still in English, so Claude wrote Japanese translations
for Garinoppi and Pinky.

#### What's Next

The vision goes deeper.
Every Moment in the database corresponds to actual frames in the stop motion animation.
Eventually, you'll be able to click on a moment and see the actual frames.
Basically be a few clicks away from seeing snippets like:

* G Choppy cutting 4poss
* Y Slider monitoring the Bearing
* Big Brother kicking a marble off the track

But given there is only one camera, the snippet might be of him on the other side of the track.  Hmmm... Marble Track 4 needs to fix this somehow.

For now, Marble Track 3 fledgling website exists at https://db.marbletrack3.com/.

#### Join the Fun!

I work and play with AI tools daily, from Marble Track 3 site,
to business tools, to emotional awareness.
Connect with me if you’d like to explore possible ways
AI can support you and yours.  https://www.robnugen.com/en/contact/
