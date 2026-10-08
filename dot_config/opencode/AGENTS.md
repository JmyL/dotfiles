# Atuin for interactive shell history

When you need commands the user ran in their own shells (other panes, "what did I run", reproduce a recent command), query **atuin** (`atuin history list` / `atuin search`). Do not use `~/.bash_history`.

This session's **agent** terminals stay the `terminals/` snapshots — atuin is for the user's interactive panes, not a substitute for those.

Do not dump large history or secrets; filter by time, cwd, or session (`ATUIN_SESSION`).

# Obsidian notes

Follow `~/Documents/Obsidian/AGENTS.md`. New-issue analysis: skill `obsidian-issue-analysis` (registered in `~/.config/opencode/skills/`).

## Must

- Create notes with Neovim **obsidian.nvim** `Obsidian new` (headless or interactive). Do **not** invent `{unix_ts}-{4CAPS}` filenames by hand.
- Wrap non-tag `#`-prefixed text (Slack channels, PR refs) in **backticks** in note bodies — a bare `#word` becomes an inline tag and pollutes tag search.
- Keep plugin-generated frontmatter (`id` / `aliases`); fill the body after create (plus the `plan` / `how-to` tag for plan/runbook notes).
- **New issue analysis** (Slack/Jira/incident + investigate): create/update the issue note and append today's daily `## Issues` — do not wait for "Obsidian" / "노트 만들어".
- **Confirmed plan / deferred runbook**: skill `obsidian-plan` — when a plan-mode plan is confirmed (or a how-to/runbook needs a home), create the Obsidian note (`plan` / `how-to` tag) and append today's daily line (`## Plans` / `## Notes`). Do not wait for the user to ask.
- Daily line format:

```markdown
- [ ] [[<id>|'<TITLE>']] — <one-line blurb>
```

## Do not

- Hand-write new zettel ids or skip `Obsidian new`
- Edit daily notes except (1) the user asked, (2) a new issue-analysis note's `## Issues` line, or (3) a new plan / how-to note's `## Plans` / `## Notes` line
- Save new agent plans or runbooks to `~/.config/plans/` (Cursor plan-UI storage only) — use Obsidian via `obsidian-plan` instead
