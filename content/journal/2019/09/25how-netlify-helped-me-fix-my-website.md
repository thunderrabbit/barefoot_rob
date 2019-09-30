---
title: "How Netlify helped me fix my website"
tags: [ "netlify", "hugo", "website", "fix", "solved" ]
author: Rob Nugen
date: 2019-09-25T07:46:38+09:00
---

My website stopped working recently.  More accurately,
[Hugo](https://gohugo.io) stopped rendering the /blog and /journal
portions of my website.  The last time it worked was 2 weeks ago.  I
noticed that my local version of Hugo had gotten updated (*) and
checked the releases.. sure enough there was a change to something
related to that I had tweaked regarding indices.

The problem languished for a while until I remembered that [Netlify
allows choosing which version of Hugo to use](https://www.netlify.com/blog/2017/04/11/netlify-plus-hugo-0.20-and-beyond/).

That, along with building every branch, allowed me to test at exactly
*which* version of Hugo my site stopped being rendered properly.

I had already created a mini version of my site, so I whipped up a
shell script `netlify.sh`to slap a bunch of different branches with different
versions of Hugo requested.

    #!/usr/bin/env bash
    
    VERSION=$1
    BRANCH=hugo${VERSION//\./}
    FILE=netlify.toml
    
    echo "version $VERSION"
    echo "branch $BRANCH"
    
    git checkout master
    git branch -f $BRANCH
    sleep 1
    git checkout $BRANCH
    
    sed -i '' s/"0.54.0"/"$VERSION"/g $FILE
    
    git add $FILE
    
    sleep 1
    
    git commit -m "Hugo $VERSION
    
    to narrow down when it stopped working"
    
    sleep 1
    
    git push origin $BRANCH
    
    sleep 1
    
    git log --oneline --graph --decorate --all

The `sleep` commands are there to keep git from locking itself out of the directory.

This allowed me to run

`./netlify.sh 0.45`

where 0.45 is a version number I wanted to test.

I thereby created a bunch of branches...

    * 77836e3 (origin/hugo0471, hugo0471) Hugo 0.47.1
    | * 1254cd2 (origin/hugo047, hugo047) Hugo 0.47
    |/
    | * 41014f0 (origin/hugo046, hugo046) Hugo 0.46
    |/
    | * cb8b953 (origin/hugo0451, hugo0451) Hugo 0.45.1
    |/
    | * ee47137 (origin/hugo0422, hugo0422) Hugo 0.42.2
    |/
    | * df2c69f (origin/hugo0403, hugo0403) Hugo 0.40.3
    |/
    | * ea775d5 (origin/hugo039, hugo039) Hugo 0.39
    |/
    | * 1caa175 (origin/hugo0382, hugo0382) Hugo 0.38.2
    |/
    | * a826419 (origin/hugo038, hugo038) Hugo 0.38
    |/
    | * 2b4b63c (origin/hugo0371, hugo0371) Hugo 0.37.1
    |/
    | * c69e973 (origin/hugo037, hugo037) Hugo 0.37
    |/
    | * 01c68bf (origin/hugo0361, hugo0361) Hugo 0.36.1
    |/
    | * 609b6c4 (origin/hugo036, hugo036) Hugo 0.36
    |/
    | * c885d55 (origin/hugo040, hugo040) Hugo 0.40
    |/
    | * a8e7ea5 (origin/hugo041, hugo041) Hugo 0.41
    |/
    | * b0a8b51 (origin/hugo042, hugo042) Hugo 0.42
    |/
    | * d1710b2 (origin/hugo043, hugo043) Hugo 0.43
    |/
    | * d3d75d0 (origin/hugo044, hugo044) Hugo 0.44
    |/
    | * 522256c (origin/hugo045, hugo045) Hugo 0.45
    |/
    * 3b956b6 (HEAD -> master, origin/master) Use baseurl = "/" for running on Netlify
    * e77f687 Simplify debugging by removing ghost files
    * e11a45e Pared down site from https://github.com/thunderrabbit/journal-hugo

And Netlify quickly created all of them so I could figure out which
ones worked and which ones did not.

* https://hugo046--angry-lumiere-228f57.netlify.com
* https://hugo045--angry-lumiere-228f57.netlify.com
* https://hugo044--angry-lumiere-228f57.netlify.com
* https://hugo043--angry-lumiere-228f57.netlify.com
* https://hugo042--angry-lumiere-228f57.netlify.com

etc etc

*None of them worked!*

    (☉_☉)

(*) The fact that the local version had gotten updated automagically
should have been a clue that the auto-updating Hugo had *not* caused
the problem.  I had no idea when the updates happened, but the problem
suddenly started, and I assumed an update was the cause.

"Well, boys, I was wrong."

### it was my mistake all along

In an attempt to fix my top page, I had tweaked this and that, where
this and that are the main repo site, and sub-module theme,
respectively.  During the process, I did not notice that I had also
broken the entire site. Part of the not noticing was due to the
current way I have Hugo set up, it does not wipe the output `public/`
directory before creating the site.  (Although I intended to and
thought I had activated that option.)

here's where it gets tricky.  My current site consists of multiple
submodules, the two mentioned above, a couple others which have not
changed in months (years), and my journal entries, which currently has
8500+ files.  There are enough journal files that when I try to run
Hugo on my site locally, it crashes with too many files open.  I
cannot let Hugo watch for changes so I have to restart Hugo each time
I make a change.

Let's see if I can offload that task to Netlify.

Basic idea:

1. Start with my local website repository
2. Wipe all files from the public/ directory
3. Copy the remaining files to a new directory
4. git checkout abcdef123 --recurse-submodules
5. Create a branch
6. Push to Netlify

or

5. Wipe most of the journal entries
6. Run the code locally

##### 12:56 Wednesday 25 September 2019 JST

Getting closer.  I made a script I called `commitlify.sh`

    #!/usr/bin/env bash
    
    COMMIT=$1
    BRANCH=hugo_${COMMIT//\./}
    
    echo "commit $COMMIT"
    echo "branch $BRANCH"
    
    rm -rf public/
    
    ls public/
    
    git checkout $COMMIT --recurse-submodules
    
    git branch -f $BRANCH
    
    sleep 1
    
    git checkout $BRANCH
    
    sleep 1
    
    git push origin $BRANCH
    
    sleep 1
    
    hugo server -w=0

It does a similar thing as the previous script, but deals with
submodules being aligned with the main repo's HEAD.  The last line
tells Hugo to serve the site, but not to monitor it for changes.

This is fine for now because I am just poking around to see which
commits were breaking commits.

##### 21:58

I found a [breaking commit that used to be a genius commit](https://bitbucket.org/thunderrabbit/purehugo/commits/16559a8ffa3ec74f57af7398a90f259f41972675), but
apparently its genius did not survive changes in Hugo.

##### 00:32 Thursday 26 September 2019 JST

And now I have gotten enough of the errors out of the system that I
can get Netlify to build *something* with the repo.  I still do not
have /blog nor /journal indices working, but getting closer.  There
were a couple of commits that did work, so .. oh I can try one now.

Dangit.  There are different errors with some commits I marked as
working in my local setup.

Too tired to work on it now.  good night!

##### 22:20 Thursday 26 September 2019 JST

Yayyy!!  As of today, I got an [old version of my site](https://new-robnugen-com-fallible-abandoned-58f942.netlify.com) working on
Netlify.

Both the
[journal](https://new-robnugen-com-fallible-abandoned-58f942.netlify.com/journal/)
and
[blog](https://new-robnugen-com-fallible-abandoned-58f942.netlify.com/blog/)
have their own pages, and the top page shows just the blog entries.

The pagination on the top page is messed up, but now that I have
something working, I can ask peeps on the Hugo forum for help on
that.  My attempt to fix that is what broke my site in the first
place.

Okay..  now to get my journal entries and blog entries up to date!

Go to main repo directory

    cd ~/journal-hugo

Keep track of the old master branch

    git branch -f old_master c670763

Move the master branch to the branch that is working now ([bbfbe552a5a6f8b9337af3ac41ee359250a309df](https://bitbucket.org/thunderrabbit/journal-hugo/commits/bbfbe552a5a6f8b9337af3ac41ee359250a309df))

    git branch -f master

It took 45 minutes to deploy before, so this may be up in 45 minutes.
https://new-robnugen-com-fallible-abandoned-58f942.netlify.com

Oh dang, I triggered a deploy by uploading my latest journal without
uploading this latest change.
