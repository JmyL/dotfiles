---
name: obsidian-note
description: >-
  Create and keep an Obsidian knowledge/reference note from a chat answer or
  explanation (tags: note) via Neovim obsidian.nvim, and list it on today's
  daily note under ## Notes (plain link). Use when the user asks to save an
  answer, explanation, or knowledge snippet as a note ("이 답변 note로 만들어
  줘", "note로 정리해 줘", "노트로 정리해 줘", "Obsidian에 정리해 줘") — for
  knowledge, not issue analysis or plans.
---

# Obsidian knowledge note

Vault: `~/Documents/Obsidian`. Create notes only with Neovim `Obsidian new` (see vault `AGENTS.md`). Do not invent `{unix_ts}-{4CAPS}` ids.

## When to run

- The user asks to save a chat answer / explanation / knowledge as a note: "이 답변 note로 만들어 줘", "이거 note로 정리해 줘", "노트로 정리해 줘".
- Do **not** use for: issue analysis (skill `obsidian-issue-analysis`), confirmed plans / how-to runbooks (skill `obsidian-plan`).

If this chat already created a note for the topic, or the vault already has one on the same topic: **update that note**. Search the vault before creating.

## New note

1. **Title** = short topic name (e.g. `XDG_RUNTIME_DIR`). Jira keys go in the body as links, not the title.
2. **Create:**

```bash
nvim --headless \
  -c 'cd ~/Documents/Obsidian' \
  -c "Obsidian new <TITLE>" \
  -c 'write' \
  -c 'lua io.stdout:write(vim.api.nvim_buf_get_name(0) .. "\n")' \
  -c 'qa'
```

3. **Frontmatter**: keep plugin-generated `id` / `aliases`; append `note` under `tags:`. This is the only frontmatter edit allowed.
4. **Body**: keep the answer's content, tightened to nearby-note density (short sections, bullets, fenced code as needed). Do not paste the whole chat. Wrap non-tag `#`-prefixed strings (Slack channels, PR refs) in backticks in the body — a bare `#word` becomes an inline tag and pollutes tag search.
5. **Daily link** (always; do not ask). Today's `YYYY-MM-DD.md`, plain link under `## Notes` (create the heading at the end if missing), no checkbox:

```markdown
- [[<id>|'<TITLE>']]
```

   Skip if the same `[[id|…]]` is already listed. Do not rewrite other daily content.

## Updates

- Later related answers on the same topic → update the same note (append sections / rewrite the affected part). No second note, no extra daily line.
- `## Notes` links are plain links, not checkboxes — nothing to check off.
