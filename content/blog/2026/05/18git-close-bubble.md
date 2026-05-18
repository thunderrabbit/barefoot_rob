---
title: "git close-bubble: Closing Merge Bubbles Without Thinking"
date: 2026-05-18T09:00:00+09:00
draft: true
tags: ["2026", "git", "workflow", "tools", "ai"]
---

#### The Merge Bubble Pattern

My git workflow is built around merge bubbles.  The idea is simple: every set of related commits lives inside a bubble — branch off, do the work, merge back with `--no-ff`.  The merge commit is the lid on the bubble.  The graph stays readable, and any set of changes has a clear start and end.

The opening commit of every bubble is a tiny BEGIN commit — literally just a version bump, nothing else.  Not empty, but deliberately minimal.  The real work starts in the second commit.  This way, the BEGIN commit is unambiguous: it marks where the bubble started, and nothing else happened there.

This is all fine in theory.  In practice, closing a bubble used to mean remembering exactly where I branched from, checking out that parent, running the merge, then getting back to my working branch.  Enough friction that I sometimes skipped the `--no-ff` and just let commits land flat.

#### git close-bubble

`git close-bubble` is a small script I wrote to handle the close-out mechanics automatically.

```bash
git close-bubble "DONE My feature description"
```

That's all.  It finds the most recent unclosed BEGIN commit in the log, checks out that commit, merges the current branch into it with `--no-ff`, then fast-forwards the topic branch to the new merge commit.

{{< ai claude >}}
Here's what the script does under the hood:

1. **Find the BEGIN commit.** It searches `git log` for commits whose message starts with `BEGIN `. Then it checks each candidate against the list of first-parents of all existing merge commits. The first BEGIN commit that hasn't already been closed is the target.

2. **Perform the merge.** `git checkout <begin-commit>`, then `git merge --no-ff <current-branch> -m "<your message>"`. This creates the merge commit with the bubble-close message *as a child of the BEGIN commit*, not as a child of the latest work — which is exactly the shape you want.

3. **Fast-forward back.** `git checkout <branch>`, then `git merge <merge-commit>`. The branch pointer now sits at the merge commit, and the graph shows a clean bubble.

The `--dry-run` flag skips all of that and just prints which BEGIN commit it would target — useful when you can't remember if you have an open bubble or not.

One deliberate omission: the script never pushes. The comment in the source says "sometimes bots pick the wrong branch and make mini-moon-sized bubbles." Inspect the graph before you push.
{{< /ai >}}

#### Dry Run First

When I'm not sure whether I have an open bubble, I run:

```bash
git close-bubble --dry-run
```

It prints the BEGIN commit it would close and exits.  No changes, no risk.  Then I can look at `git log --oneline` and confirm it found the right one before committing to the close.

#### The No-Push Is Intentional

The script ends with:

> *Done. Branch 'X' now points at Y. Inspect, then 'git push' when satisfied.*

That pause is load-bearing.  Automated agents (including my own) have occasionally run this on the wrong branch.  The visual inspection before push is the last sanity check.  I've caught mistakes there that would have been annoying to unwind from the remote.

#### Why Bother?

Flat commit history is fine until you want to understand what a set of changes was *for*.  A merge bubble gives every change a subject — the DONE message — and a clear boundary.  `git log --merges --oneline` becomes a summary of the project, not just a list of micro-edits.

The BEGIN/DONE pair is cheap to write.  `git close-bubble` makes the close-out cheap too.  Now I actually do it.
