# Publishing to Substack from Claude Code

This guide sets up **substack-mcp-plus**, an MCP server that gives Claude Code
tools to create drafts and publish posts on your Substack newsletter.

Your workflow: publish on robnugen.com first, then use `/publish-substack` in
Claude Code to cross-post to https://robnugen.substack.com/.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Fork and Clone](#2-fork-and-clone)
3. [Install](#3-install)
4. [Authenticate](#4-authenticate)
5. [Configure Claude Code](#5-configure-claude-code)
6. [Test It](#6-test-it)
7. [The Skill](#7-the-skill)
8. [Daily Workflow](#8-daily-workflow)
9. [Known Limitations](#9-known-limitations)
10. [Troubleshooting](#10-troubleshooting)
11. [Maintenance](#11-maintenance)

---

## 1. Prerequisites

- **Node.js** >= 16
- **Python** >= 3.10 (the MCP library requires it)
- **Playwright's Chromium** (the auth wizard opens a real browser window)
- A Substack account with **email + password** login
  - If you currently sign in with Google/Apple, go to Substack account settings
    and set a password first

Check your versions:

```bash
node --version    # v16+ required
python3 --version # 3.10+ required
```

---

## 2. Fork and Clone

DONE. Cloned to `~/work/rob/substack-mcp-plus`.

Why fork instead of `npm install -g`?

- Three open bugs affect formatting (Issues #3, #4, #5). You may want to apply
  fixes yourself or pull in community PRs.
- Pinning to your fork means Substack API changes won't surprise you via an
  auto-update.

---

## 3. Install

DONE. `npm install` succeeded and installed all Python dependencies into `venv/`.

---

## 4. Authenticate ← YOU ARE HERE

The setup script needs Playwright, which is installed in the venv -- not system
Python. Running `python3 setup_auth.py` directly won't work.

**Option A: Activate the venv first, then run setup_auth.py**

```bash
cd ~/work/rob/substack-mcp-plus
source venv/bin/activate
playwright install chromium    # download browser binary (first time only)
python3 setup_auth.py
```

**Option B: Use the npm wrapper** (it should find the venv Python automatically)

```bash
cd ~/work/rob/substack-mcp-plus
source venv/bin/activate
playwright install chromium    # download browser binary (first time only)
./node_modules/.bin/substack-mcp-plus-setup
```

Either way, you **must** activate the venv first and install Chromium.

The wizard will:

1. Ask you to choose: **Magic Link** (6-digit code emailed to you) or **Password**
2. Ask for your email address
3. Open a visible Chrome browser window to Substack's sign-in page
4. Auto-fill your credentials
5. **You solve any CAPTCHA manually** in the browser window (it waits up to 2 minutes)
6. After successful login, it extracts the `substack.sid` cookie
7. Encrypts and stores the token

**Token storage:** `~/.substack-mcp-plus/`

| File | Contents |
|------|----------|
| `auth.json` | Encrypted token, email, expiry (30 days) |
| `.key` | Fernet encryption key |

Both files are chmod 600 (owner-only).

**Alternative auth** (if the wizard doesn't work): extract cookies manually:

1. Log into substack.com in your browser
2. Open DevTools (F12) > Application > Cookies > https://substack.com
3. Copy the value of `substack.sid`
4. Set the environment variable:
   ```bash
   export SUBSTACK_SESSION_TOKEN="your_substack_sid_value"
   ```

Auth priority (the server tries these in order):

1. Stored encrypted token (from setup wizard)
2. `SUBSTACK_SESSION_TOKEN` environment variable
3. `SUBSTACK_EMAIL` + `SUBSTACK_PASSWORD` environment variables

---

## 5. Configure Claude Code

Add the MCP server to your **project-level** settings so it's available when
working in barefoot_rob_master:

Edit (or create) `.claude/settings.json` in your project root:

```json
{
  "permissions": {
    "allow": []
  },
  "mcpServers": {
    "substack-mcp-plus": {
      "command": "/home/thunderrabbit/work/rob/substack-mcp-plus/node_modules/.bin/substack-mcp-plus",
      "env": {
        "SUBSTACK_PUBLICATION_URL": "https://robnugen.substack.com"
      }
    }
  }
}
```

After editing, restart Claude Code for the MCP server to load.

---

## 6. Test It

Start a new Claude Code session and check that the tools are available:

```
You: list my substack drafts
```

Claude should call the `list_drafts` tool and show your drafts. If it says
the tool isn't available, check:

- Is the MCP server path correct in `.claude/settings.json`?
- Did you restart Claude Code after adding the config?
- Run the server manually to see errors:
  ```bash
  SUBSTACK_PUBLICATION_URL=https://robnugen.substack.com \
    /home/thunderrabbit/work/rob/substack-mcp-plus/node_modules/.bin/substack-mcp-plus
  ```

---

## 7. The Skill

A Claude Code skill file lives at `.claude/skills/publish-substack/SKILL.md`
in this project. It was created alongside this guide.

**Usage:**

```
/publish-substack content/blog/2026/03/02two_agents_one_jquery_upgrade.md
```

Or without arguments (Claude will find the most recent blog post):

```
/publish-substack
```

The skill instructs Claude to:

1. Read the blog post file
2. Strip Hugo frontmatter, extract title and content
3. Convert robnugen.com image URLs so they work on Substack
4. Create a draft on Substack
5. Show you the draft for review
6. Publish only after you confirm

---

## 8. Daily Workflow

1. Write and publish a blog post on robnugen.com (via Hugo as usual)
2. Wait an hour (or however long you like)
3. In Claude Code:
   ```
   /publish-substack content/blog/2026/03/02two_agents_one_jquery_upgrade.md
   ```
4. Claude creates a Substack draft, shows you a summary
5. You confirm, Claude publishes, subscribers get emailed

For the current pending post, the file is:
`content/blog/2026/03/02two_agents_one_jquery_upgrade.md`

---

## 9. Known Limitations

These are significant -- plan to do a final check in Substack's web editor:

| Issue | Impact | Workaround |
|-------|--------|------------|
| **Bold/italic may render as literal `**text**`** | Inline formatting lost (GitHub Issue #4) | Edit in Substack web editor before publishing |
| **Images render as `![alt](url)` text** | Images not displayed (GitHub Issue #5) | Add images via Substack web editor |
| **Links render as `[text](url)` text** | Links not clickable (GitHub Issue #4) | Edit in Substack web editor |
| **No scheduling** | Cannot schedule future publish | Schedule via Substack web editor |
| **Publish sends email immediately** | No "publish silently" option | N/A -- consider creating as draft then publishing from web UI |
| **Token expires after 30 days** | Auth stops working | Re-run `substack-mcp-plus-setup` |
| **Unofficial API** | May break if Substack changes endpoints | Monitor upstream repo for fixes |

**Recommended workflow given these limitations:**

1. Use `create_formatted_post` to create a draft (gets the text in there)
2. Open the draft in Substack's web editor to fix formatting and add images
3. Publish from the web editor

OR: create the draft via MCP, review it, and if the formatting looks good
enough, publish directly via MCP. Headers and plain paragraphs usually work fine.

---

## 10. Troubleshooting

| Problem | Solution |
|---------|----------|
| "No authentication found" | Run `substack-mcp-plus-setup` |
| CAPTCHA during setup | Solve it manually in the browser window |
| Token expired | Re-run `substack-mcp-plus-setup` |
| Import errors on server start | `cd ~/work/rob/substack-mcp-plus && source venv/bin/activate && pip install -e .` |
| Tools not discovered | May be Issue #3; check if `capabilities` is set correctly in `src/server.py` |
| Subscriber count shows 0 | Known API limitation; check Substack dashboard |
| Debug logging | `export SUBSTACK_MCP_DEBUG=true` |
| Reset everything | `rm -rf ~/.substack-mcp-plus/ && substack-mcp-plus-setup` |

---

## 11. Maintenance

### Updating

```bash
cd ~/work/rob/substack-mcp-plus
git fetch upstream   # or origin if you didn't add upstream
git merge upstream/main
npm install          # re-runs postinstall
```

### Applying community fixes

The three open issues (#3, #4, #5) have proposed fixes. Check if PRs have been
merged upstream, or apply them to your fork:

```bash
# Example: pull a specific PR
gh pr checkout 5 --repo ty13r/substack-mcp-plus
# Test it, then merge to your main branch
```

### Auth token refresh

Tokens expire every 30 days. When publishing stops working:

```bash
./node_modules/.bin/substack-mcp-plus-setup
```

---

## Available MCP Tools Reference

Once configured, Claude Code gains these 12 tools:

| Tool | What it does |
|------|-------------|
| `create_formatted_post` | Create a new draft from markdown content |
| `update_post` | Replace title/content/subtitle of an existing draft |
| `publish_post` | Publish a draft immediately (sends email to subscribers) |
| `list_drafts` | List recent drafts with IDs (max 25) |
| `list_published` | List recent published posts |
| `get_post_content` | Read full post content as markdown |
| `duplicate_post` | Copy an existing post as a new draft |
| `upload_image` | Upload a local image to Substack's CDN |
| `preview_draft` | Generate a preview link (author-only) |
| `get_sections` | List publication sections/categories |
| `get_subscriber_count` | Get subscriber count |
| `delete_draft` | Permanently delete a draft |

---

## Links

- Upstream repo: https://github.com/ty13r/substack-mcp-plus
- npm package: https://www.npmjs.com/package/substack-mcp-plus
- Underlying Python library: https://github.com/ma2za/python-substack
- Your Substack: https://robnugen.substack.com/
- Your blog: https://www.robnugen.com/en/blog/
