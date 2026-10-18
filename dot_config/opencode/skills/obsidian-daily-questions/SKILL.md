---
name: obsidian-daily-questions
description: >-
  Two daily-note workflows for the Obsidian vault: (1) answer each question in
  the daily's `## Questions` section inline, directly below the question
  ("Daily의 questions 답변해 줘", "questions 답변해 줘"); (2) convert each
  question (plus its answer) into its own knowledge note, then delete the
  question entries from `## Questions` and list the new notes under `## Notes`
  ("questions를 note로 만들어 줘", "question note로", "질문들 note로 정리해 줘").
---

# Obsidian daily questions

Vault: `~/Documents/Obsidian`. Daily notes are `YYYY-MM-DD.md` at the vault root (see vault `AGENTS.md`). Use today's daily unless the user names another date. Create notes only with Neovim `Obsidian new` — do not hand-write `{unix_ts}-{4CAPS}` ids.

Two user commands. Ask nothing if the target date is clear; both flows must not rewrite unrelated daily content.

## Flow 1 — "Daily의 questions 답변해 줘" (answer inline)

1. Read the daily note, find the `## Questions` section. No section or no questions → say so and stop.
2. For **each** question entry, write the answer **directly below that question** as indented sub-lines (one tab). Keep the question's checkbox and text untouched.
3. Answer style: concise bullets; Korean fine. Verify claims with real commands when cheap and include the evidence (command + key output), so the answer stands alone later.
4. Leave every other section alone.

```markdown
- [ ] What does nvidia toolkit do?
	- 컨테이너 **생성 시점**에 호스트 드라이버 유저스페이스 lib을 주입 + symlink 생성 + 디바이스 연결 + ldconfig 갱신 …
```

## Flow 2 — "questions를 note로" (one note per question, then clean up)

For each question in `## Questions` (use its inline answer from Flow 1 if present; if unanswered, answer it first — same evidence rules):

1. **Title** = the question reworked so the title alone explains the topic (drop filler, add the concrete subject). **No `/` in titles** — Obsidian paths cannot contain it.
2. **Create** via headless `Obsidian new`:

```bash
nvim --headless \
  -c 'cd ~/Documents/Obsidian' \
  -c "Obsidian new '<TITLE>'" \
  -c 'write' \
  -c 'lua io.stdout:write(vim.api.nvim_buf_get_name(0) .. "\n")' \
  -c 'qa'
```

	- **Quote the title** inside the `-c` string. Without quotes, similar titles get dedupe-merged into an existing note ("Updated note …" instead of "Created note …").
	- Count the "Created" lines: one per question. If any iteration only "Updated" an existing note, inspect that note and fix the alias/title by hand rather than leaving a mangled merge.
3. **Body** = the original question + the answer (+ evidence commands in fenced blocks). Keep plugin frontmatter (`id` / `aliases`), append `note` under `tags:`. Wiki-link sibling notes where they reference each other.
4. **Daily cleanup** — this is what makes Flow 2 different from `obsidian-note`:
	- **Delete** the question entries (and their inline answers) from `## Questions`. If the section ends up empty, remove the heading too.
	- Add one **plain link per note** under `## Notes` (create the heading at the end if missing), no checkbox:

```markdown
- [[<id>|'<TITLE>']]
```

5. Do not rewrite other daily content; do not commit the vault unless asked.
