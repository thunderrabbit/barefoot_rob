# Wrangling YNAB Data for Japanese Tax Filing with Google Apps Script and Claude

Since March 2024, I track all my spending in YNAB (You Need A Budget). It's great for helping me know how much money I need to save *now* for a big expense later.

Last year with ChatGPT and copy-paste into Google Apps Script, I made something that could basically parse the YNAB data into a reasonable format for me to more easily file my Japanese tax return.

This year, I was able to make it even better with Claude Code on command line, plus [`clasp`](https://github.com/google/clasp) (Google's Command Line Apps Script tool).

This line and above are written by Rob.  Below is written by Claude:

::: ai claude
## The Setup

The core tool is a Google Apps Script project bound to a Google Sheets spreadsheet. The workflow is simple:

1. Export a year's worth of transactions from YNAB as CSV
2. Paste the data into a sheet called `YNAB DATA HERE`
3. Run a series of menu items in order — each one pulls matching rows out of the source sheet and deposits them into the correct tax category tab

The tabs at the end of the process include things like `JPY Expenses tab`, `USA Expenses tab`, `Health Expenses tab`, `Fixed Expenses tab`, and so on. Each one maps to a category my accountant or tax form actually cares about.

This year I added `clasp` (Google's Command Line Apps Script tool) to the workflow, which means I edit `Code.gs` locally, push with `clasp push`, and track everything in git. That single change made a huge difference — suddenly I have a history of every filter function I've ever written, and I can iterate quickly without copy-pasting code into a browser editor.

## The Tax Law Constraint Problem

Here's where it gets interesting. Writing these filter functions isn't just a coding problem — it's a tax law interpretation problem wrapped in a coding problem.

Take a recent example: I attend monthly MKP Japan meetings. I founded MKP Japan a decade ago. I spend money getting there (train fare) and sometimes on food. Is that a business expense?

Probably not. The primary purpose is personal and community-oriented. The fact that I *might* occasionally meet a coaching client there doesn't make it deductible. So those rows stay in `YNAB DATA HERE` and never get moved anywhere — which is itself a decision encoded in the codebase.

Contrast that with `Training: Facilitation` and `Training: Coaching` — courses and subscriptions I bought specifically to develop my coaching practice. Those go straight to the Training expenses tab. The filter function that handles them is almost trivially simple:

```javascript
function addTrainingExpenses() {
  moveTheseExpensesToSheets('Training', function(row) {
    var categoryGroup = row[4];
    return categoryGroup === 'Training: Facilitation' ||
           categoryGroup === 'Training: Coaching';
  }, [SHEET_JPY_EXPENSES]);
}
```

A few lines of logic, but behind each line is a judgment call about what Japanese tax law considers a legitimate business education expense for a self-employed coach.

## Where AI Collaboration Actually Helps

The coding itself is not especially hard. Google Apps Script is JavaScript. Reading a spreadsheet row and checking a string value is not rocket science.

What's hard is the *volume* of small decisions. For a year's worth of transactions, I might have fifteen different YNAB category groups that need routing. Each one requires:

- Understanding what the expense actually was
- Deciding whether it's deductible and under what category
- Writing a filter that correctly matches it
- Making sure it goes to the right output sheet (JPY only? Both JPY and USA?)
- Not accidentally catching rows that should stay unhandled

Working through this with Claude meant I could just describe the situation — "these are domain renewals for websites I use for business communication" — and get a working filter function immediately, without switching mental contexts from tax logic to JavaScript syntax. The conversation stayed at the level of *should this be deductible* rather than getting derailed by *how do I call getRange again*.

Claude also caught things I would have glossed over. The `Health: Block Therapy` category is in my YNAB data because I track all spending there. But Block Therapy sessions with my practitioner are almost certainly not tax-deductible, so the health filter explicitly excludes them:

```javascript
return row[4].startsWith('Health:') && row[4] !== 'Health: Block Therapy';
```

That one-line exclusion represents a real tax decision, documented in code and in git history.

## The Fixed Expenses Tab: A More Complex Layout

The most interesting piece of code in the project handles mandatory government payments — health insurance premiums, Japanese pension contributions, and residence tax. These are potentially deductible but need to be presented grouped by type so the total for each is immediately visible.

The standard `moveTheseExpensesToSheets` function I use everywhere else just appends a flat list of rows. For this tab I needed:

- Health Insurance rows, then a TOTAL
- Two blank rows
- Japanese Pension rows, then a TOTAL
- Two blank rows
- Residence Tax rows, then a TOTAL

That required a custom function. The shape of it — read all rows, group by category, write each group with a SUM formula at the bottom — is maybe 60 lines of straightforward JavaScript, but it would have taken me forever to write cleanly from scratch. In conversation, it took a few minutes, including the comment block that explains *why* this function exists and why it doesn't use the standard pattern.

## The Bigger Picture

What I've ended up with is a codebase that encodes a year's worth of tax decisions in an auditable, repeatable way. Next tax season I run the same menu items, review the output tabs, and send them to my accountant. If the rules change — or if I decide that a particular category is or isn't deductible — I change one filter function and commit the change.

The git history is also genuinely useful. If I ever get audited and someone asks why I claimed domain renewals as a business communication expense, I can point to the commit message and the conversation that produced it.

None of this required a particularly sophisticated AI. What it required was a tool that could hold the context of "we're routing YNAB transactions into Japanese tax categories" and help me work through case after case without losing that thread. That's exactly what Claude is good at.

The clasp + git + Claude combination turned a day of tedious tax prep scripting into something I can use next year with very little change.
:::