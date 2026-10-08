# Atuin for interactive shell history

When you need commands the user ran in their own shells (other panes, "what did I run", reproduce a recent command), query **atuin** (`atuin history list` / `atuin search`). Do not use `~/.bash_history`.

This session's **agent** terminals stay the `terminals/` snapshots — atuin is for the user's interactive panes, not a substitute for those.

Do not dump large history or secrets; filter by time, cwd, or session (`ATUIN_SESSION`).

# Obsidian notes

Follow `~/Documents/Obsidian/AGENTS.md`. New-issue analysis: skill `obsidian-issue-analysis` (registered in `~/.config/opencode/skills/`).

## Must

- Create notes with Neovim **obsidian.nvim** `Obsidian new` (headless or interactive). Do **not** invent `{unix_ts}-{4CAPS}` filenames by hand.
- Wrap non-tag `#`-prefixed text (Slack channels, PR refs) in **backticks** in note bodies — a bare `#word` becomes an inline tag and pollutes tag search.
- Keep plugin-generated frontmatter (`id` / `aliases`); only fill the body after create.
- **New issue analysis** (Slack/Jira/incident + investigate): create/update the issue note and append today's daily `## Issues` — do not wait for "Obsidian" / "노트 만들어".
- Daily line format:

```markdown
- [ ] [[<id>|'<TITLE>']] — <one-line blurb>
```

## Do not

- Hand-write new zettel ids or skip `Obsidian new`
- Edit daily notes except (1) the user asked, or (2) a new issue-analysis note's `## Issues` line
- Put agent/infra implementation plans in the vault (use `~/.config/plans/` or `~/.config/work/plans/`)
