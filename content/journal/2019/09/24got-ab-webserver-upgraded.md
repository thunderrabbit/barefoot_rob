---
title: "got AB webserver upgraded"
tags: [ "work", "yay", "finally" ]
author: Rob Nugen
date: 2019-09-24T17:37:10+09:00
---

I got AB's server upgraded from unsupported Ubuntu 12 to Ubuntu 18.
Now running PHP 7 instead of unsupported 5.6  Now running RDS instead
of MySQL on EC2.

Not yet running ALB, but AWS tech team is looking into why the
application was sometimes throwing 502 errors when I routed requests
through ALB.
