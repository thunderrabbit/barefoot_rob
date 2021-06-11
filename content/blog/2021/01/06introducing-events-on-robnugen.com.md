---
title: "Introducing /events on robnugen.com"
tags: [ "events", "website", "hugo" ]
categories: [ "blog" ]
author: Rob Nugen
draft: false
date: 2021-01-06T08:08:37+09:00
---

Thanks to my friend Hide for *not* being on Facebook when I wanted to
invite him to my walking event.  That was the proverbial push that got
me to create an /events listing.

For about a month it has not been linked from my top page because the
events *publish* dates were shown, in stark contrast to the *event*
date.  Here is an example of that. Notice how the publish date at the
top of the event differs from the event date within the event.

https://5fe490b67b688d0008f7c403--www-robnugen-com.netlify.app/events/
([screenshot of date conflicts](https://b.robnugen.com/blog/2021/2020_dec_22_events_showed_conflicted_dates.png))

I added the event dates to each event entry and showed the *event*
dates instead of the publish dates.  Here might be a version of the
site in that state.  Notice how the Walking Meditation is happening
*after* Your Art Matters, but it shows up *first*.

https://5feff4c06fac18000796a157--www-robnugen-com.netlify.app/events/
([screenshot of events out of order](https://b.robnugen.com/blog/2021/2021_jan_04_events_were_out_of_order.png))

And then I got the indexing to work the way I want for now.  Upcoming
events are shown at top, starting with the one coming first, then Past
events are shown in summary below that, starting with the most recent.

https://5ff566470ba77500076609e2--www-robnugen-com.netlify.app/events/
([screenshot of Upcoming events](https://b.robnugen.com/blog/2021/2021_jan_07_upcoming_events_start_with_next_event.png))
([screenshot of Past events](https://b.robnugen.com/blog/2021/2021_jan_07_summaries_of_past_events.png))

I got Hugo to show future events like this

https://github.com/thunderrabbit/barefoot_rob/commit/eabe44520fb8c906f7c4323f172134a9a10048dd
