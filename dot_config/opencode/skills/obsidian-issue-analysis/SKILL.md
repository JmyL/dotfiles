---
name: obsidian-issue-analysis
description: >-
  Create and keep an Obsidian issue-analysis note (herdr workspace, user
  description, Slack/Jira links, running summary) via Neovim obsidian.nvim, and
  list it on today's daily note under ## Issues. Use when the user starts
  analyzing a new issue, incident, Slack thread, or Jira ticket, or when later
  findings should update that note — even if they do not say Obsidian or note.
---

# Obsidian issue analysis

Vault: `~/Documents/Obsidian`. Create notes only with Neovim `Obsidian new` (see vault `AGENTS.md`). Do not invent `{unix_ts}-{4CAPS}` ids.

## When to run

Start this on a **new issue analysis**, without waiting for “노트 만들어” / “Obsidian”:

- Slack / Jira / incident / vayplay link plus “왜 / 분석 / 봐줘 / investigate”
- A symptom or description they want looked into

Do **not** start a new note for: already-known ticket implementation, one-off code questions, dotfiles/infra, or plans (`~/.config/plans/` / `~/.config/work/plans/`).

If this chat already has a note, or the vault already has one for the same Jira key / Slack URL / title: **update that note**. Search the vault before creating.

## New note

1. **Title** = their description / symptom as given. Jira keys belong in the body as links, not the title.
2. **Herdr workspace** (the pane where analysis started):

```bash
herdr workspace get "$HERDR_WORKSPACE_ID"
```

   Use `result.workspace.label`, then strip a navigator prefix `^[^\s]+:\s+` (`project: ree-drive` → `ree-drive`). If `HERDR_WORKSPACE_ID` is unset, write `unknown`.

3. **Create:**

```bash
nvim --headless \
  -c 'cd ~/Documents/Obsidian' \
  -c "Obsidian new <TITLE>" \
  -c 'write' \
  -c 'lua io.stdout:write(vim.api.nvim_buf_get_name(0) .. "\n")' \
  -c 'qa'
```

   Keep plugin frontmatter (`id` / `aliases`). Fill the body only.

   Wrap non-tag `#`-prefixed strings (Slack channels, PR refs) in backticks in the body — a bare `#word` becomes an inline tag and pollutes tag search.

4. **Body** (keep nearby-note density: links + short bullets):

```markdown
# <TITLE>

- Herdr workspace: `<name>`
- <their description, kept close to their wording>
- <Slack / Jira / other links they gave>

## Summary

<running analysis summary>

## Findings

- <what we know so far>
```

5. **Daily link** (this workflow always does this; do not ask). Today’s `YYYY-MM-DD.md` under `## Issues` (create the heading at the end if missing). Do not rewrite other daily content. Skip if the same `[[id|…]]` is already listed.

```markdown
- [ ] [[<id>|'<TITLE>']] — <one-line blurb>
```

   Prefer wiki-link `[[id|title]]`. Quote the display title as `'<TITLE>'`.

## Later findings

Same note: add new Slack/Jira/session links under the top list; rewrite **Summary** so it stays current; append dated bullets under **Findings**. Do not create a second note. Do not add another daily line.
