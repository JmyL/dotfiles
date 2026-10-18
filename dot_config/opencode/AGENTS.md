# Atuin for interactive shell history

When you need commands the user ran in their own shells (other panes, "what did I run", reproduce a recent command), query **atuin** (`atuin history list` / `atuin search`). Do not use `~/.bash_history`.

This session's **agent** terminals stay the `terminals/` snapshots — atuin is for the user's interactive panes, not a substitute for those.

Do not dump large history or secrets; filter by time, cwd, or session (`ATUIN_SESSION`).

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
