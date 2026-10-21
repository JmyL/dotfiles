# Atuin for interactive shell history

When you need commands the user ran in their own shells (other panes, "what did I run", reproduce a recent command), query **atuin** (`atuin history list` / `atuin search`). Do not use `~/.bash_history`.

This session's **agent** terminals stay the `terminals/` snapshots — atuin is for the user's interactive panes, not a substitute for those.

Do not dump large history or secrets; filter by time, cwd, or session (`ATUIN_SESSION`).

# pi.dev package search

When the user asks to find a pi package/extension, search pi.dev with the `?name=` query (e.g. `https://pi.dev/packages?name=mode`), not just the default gallery landing page — the landing page is sorted/paginated and misses popular packages. Don't conclude a package doesn't exist from the landing page alone.

# Terminal glyph rendering (kitty)

Do not use circled/enclosed characters in terminal output. kitty renders them in a single narrow cell, so they come out tiny and hard to read (measured on this setup: ① ink 9×9px vs 16px for Hangul).

- **Banned:** circled digits / enclosed alphanumerics (①②③ ⓵ ⓿, U+2460–24FF) and dingbat circled digits (❶❷❸ ➊➋➌, U+2776–2793). Use plain `1.` `2.` numbering instead.
- **Verified-large exception:** emoji keycap sequences like 1️⃣ 2️⃣ (digit + VS16 + U+20E3) — they render wide (2 cells) at full size, same as 🔟.
- Korean circled Hangul (㉠㉡, U+3260+) also renders wide and is fine in Korean text.
- **Nerd Font PUA icons (U+E000–U+F8FF, U+F0000–U+FFFFD: weather, devicons, octicons, …) are now wide-expanding:** kitty pins the whole Nerd Fonts PUA range to the non-Mono face, so icons wider than a cell expand into the following space cell. Do **not** use them in monospace-critical output — markdown tables, aligned columns, ASCII diagrams, diff-like output — or columns drift. Safe in prompts/status lines/free text; just remember they consume the trailing space.

# Communication style (Sungsik)

When Sungsik's earlier wording in a thread caused a misunderstanding (Slack/Jira/PR/email), draft corrections in this order — he considers this easiest for others to follow:

1. **Fix own expression first, state position precisely** — restate the corrected point plainly ("had typos, what I meant is ..."), with prod/dev-style scope or division-of-labor made explicit.
2. **Then address each misunderstanding point**, referencing the other person's claim explicitly (@name, short quote) and answering it directly rather than re-asserting the original position.

Apply the same order when advising on or analyzing such threads. If Sungsik's message would reopen a settled debate, point out which part still needs a direct response to the other side.

For answering Sungsik's questions: if the question is simple, just answer it directly. But when his question shows a partial misunderstanding and answering it as-asked would be confusing or misleading, first give the correct explanation clearly, then follow with a brief direct answer to the original question. This makes the actual answer clearer and shorter.

# No direct PR / review comments

Never post comments or replies directly to PRs or similar review surfaces (GitHub review threads, issue comments) — not even for approved drafts. Always present the drafted text in chat and let Sungsik post it himself. Direct posting only when Sungsik explicitly asks for that exact comment in that turn. Jira/Slack posting flows in vay-* skills are unaffected.

# Obsidian notes

Follow `~/Documents/Obsidian/AGENTS.md`. Skills registered in `~/.config/opencode/skills/`: `obsidian-issue-analysis` (new-issue analysis), `obsidian-plan` (plans / how-to runbooks), `obsidian-note` (knowledge notes), `obsidian-daily-questions` (daily `## Questions`: inline answers / question→note migration).

## Must

- Create notes with Neovim **obsidian.nvim** `Obsidian new` (headless or interactive). Do **not** invent `{unix_ts}-{4CAPS}` filenames by hand.
- Wrap non-tag `#`-prefixed text (Slack channels, PR refs) in **backticks** in note bodies — a bare `#word` becomes an inline tag and pollutes tag search.
- Keep plugin-generated frontmatter (`id` / `aliases`); fill the body after create (plus the `plan` / `how-to` / `note` tag for plan/runbook/knowledge notes).
- **New issue analysis** (Slack/Jira/incident + investigate): create/update the issue note and append today's daily `## Issues` — do not wait for "Obsidian" / "노트 만들어".
- **Confirmed plan / deferred runbook**: skill `obsidian-plan` — when a plan-mode plan is confirmed (or a how-to/runbook needs a home), create the Obsidian note (`plan` / `how-to` tag) and append today's daily line (`## Plans` / `## Notes`). On completion, swap `plan` → `done-plan` and append `## Outcome` (result + links) to the note; the daily checkbox stays the user's job. Do not wait for the user to ask.
- **Knowledge note** ("이 답변 note로 …", "note로 정리해 줘"): skill `obsidian-note` — create/update the note (`note` tag) and append a plain link under today's daily `## Notes`. Reuse the same-topic note instead of a second one.
- **Plan lookup**: when asked to check/find a plan (e.g. "plan 확인해 봐"), search only the `~/Documents/Obsidian` vault — do NOT hunt for plan files in repos, home directory, or `~/.config/plans/`.
- Daily line format:

```markdown
- [ ] [[<id>|'<TITLE>']] — <one-line blurb>
```

## Do not

- Hand-write new zettel ids or skip `Obsidian new`
- Edit daily notes except (1) the user asked, (2) a new issue-analysis note's `## Issues` line, (3) a new plan / how-to note's `## Plans` / `## Notes` line, or (4) a new knowledge note's `## Notes` line
- Save new agent plans or runbooks to `~/.config/plans/` (Cursor plan-UI storage only) — use Obsidian via `obsidian-plan` instead
