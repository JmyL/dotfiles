---
name: obsidian-plan
description: >-
  Create and keep an Obsidian note for a confirmed opencode plan (tags: plan) or
  a deferred how-to runbook (tags: how-to) via Neovim obsidian.nvim, and list it
  on today's daily note (## Plans for plans, ## Notes for how-tos). Use when a
  plan-mode plan is confirmed or approved, when the user asks to save or defer a
  plan ("plan 저장", "나중에 하자"), or when a runbook/how-to needs a home —
  even if they do not say Obsidian or note.
---

# Obsidian plan notes

Vault: `~/Documents/Obsidian`. Create notes only with Neovim `Obsidian new` (see vault `AGENTS.md`). Do not invent `{unix_ts}-{4CAPS}` ids.

## When to run

- A **plan-mode plan is confirmed** — the user switches to build mode, says go/approve, or the plan is about to be executed. Create the note before starting implementation; do not wait for "노트 만들어".
- The user asks to save or defer a plan.
- A deferred how-to / runbook / wiring doc needs a home (tag `how-to` instead of `plan`).

If this chat already created a note for the plan, **update that note** instead of a second one.

## New note

1. **Title** = short plan name (e.g. `Fix swaync vs mako`). Jira keys belong in the body as links, not the title.
2. **Create:**

```bash
nvim --headless \
  -c 'cd ~/Documents/Obsidian' \
  -c "Obsidian new <TITLE>" \
  -c 'write' \
  -c 'lua io.stdout:write(vim.api.nvim_buf_get_name(0) .. "\n")' \
  -c 'qa'
```

3. **Frontmatter**: keep plugin-generated `id` / `aliases`; append the type tag under `tags:` — `plan` for plans, `how-to` for runbooks. This is the only frontmatter edit allowed.
4. **Body** for plans (keep nearby-note density; do not paste the whole chat):

```markdown
# <TITLE>

- Herdr workspace: `<name>`
- <goal one-liner / context links (Jira, Slack, PR)>

## Approach

<what changes, what stays stable>

## Tasks

- [ ] <small task — with its validation step>

## Risks

- <assumptions / open questions>
```

   Herdr workspace: `herdr workspace get "$HERDR_WORKSPACE_ID"` → `result.workspace.label`, strip a navigator prefix `^[^\s]+:\s+`. If `$HERDR_WORKSPACE_ID` is unset, write `unknown`.

   How-to runbooks: same shape minus Tasks — keep steps as the body; tag `how-to`.

   Wrap non-tag `#`-prefixed strings (Slack channels, PR refs) in backticks in the body — a bare `#word` becomes an inline tag and pollutes tag search.

5. **Daily link** (always; do not ask). Today's `YYYY-MM-DD.md`, create the heading at the end if missing. Do not rewrite other daily content. Skip if the same `[[id|…]]` is already listed:

```markdown
- [ ] [[<id>|'<TITLE>']] — <one-line blurb>
```

   Plans go under `## Plans`. How-to runbooks go under `## Notes` as a plain link `- [[<id>|'<TITLE>']]` (no checkbox).

## Updates

- Plan changes during implementation → edit the same note (mark Tasks checkboxes as work completes). No second note, no extra daily line.
- Completing the daily checkbox is the user's job — append-only; do not check it off.

## Cursor

Cursor plan-UI files keep landing in `~/.config/plans/` (via the `~/.cursor/plans` symlink). Do not move or mirror them into the vault.
