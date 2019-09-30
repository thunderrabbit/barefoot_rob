---
title: "Maintaining state in long projects"
tags: [ "perfection", "projects", "productivity", "sanity" ]
categories: [ "programming" ]
author: Rob Nugen
date: 2019-07-03T18:42:57+09:00
---

As a programmer, I often want things to be just right, finding that
balance between maintainability, extensibility, and plain ol'
get-'er-done.  Today, banging my head against unexpected walls while
trying to spin up a virtual machine with Vagrant, I had to keep my
focus on the goal at hand:  Keep the website up while migrating from
PHP 5.7 on Ubuntu 14 to PHP 7.2 on Ubuntu 18.

In this case, the task seemed simple.  Write an email to Client so
they know the status of the project.

<!-- (There was an article on HN recently with a draft letter on why some
changes take so long.  To get this blog entry just right, I should
find and link to that article.) -->

The tip for today is to keep a stack of tasks written down so I can
recall where I am headed.

1. Write an email
- Estimate price of RDS
- Make sure I can test MySQL locally
- Spin up local instance of Ubuntu 18
- Upgrade Vagrant
- Upgrade local copy of Ubuntu 18
- Install latest copy of website source
- Run tests
- Install test framework
- Need to install PHP modules
- ...

I ran out of time around that point, and still had not done the first
item on my list.  Fortunately, I still remember what I was trying to
do, and can come back to it with fresh eyes tomorrow.
