<!-- 8eb8459a-dd42-43df-b114-86c4d9793dc5 -->
---
todos:
  - id: "mcp-rule"
    content: "Add mcp-oauth-auth.mdc; delete slack-mcp-auth.mdc"
    status: pending
  - id: "dotfiles-rule"
    content: "Add short dotfiles-agents.mdc pointing at ~/.config/AGENTS.md"
    status: pending
  - id: "chezmoi"
    content: "chezmoi-work add + commit/push work dotfiles"
    status: pending
isProject: false
---
# Merge MCP auth rules and point at AGENTS.md

## Changes

### 1. Replace Slack-only rule with general MCP OAuth rule

- Create [`~/.cursor/rules/mcp-oauth-auth.mdc`](/home/sungsik/.cursor/rules/mcp-oauth-auth.mdc) (`alwaysApply: true`) covering Slack, Atlassian, and other remote OAuth MCPs.
- Behavior to encode:
  - If a **needed** namespace is `needsAuth` / tools unavailable: **stop before answering**; ask `agent mcp login <namespace>`; wait for confirmation; rediscover; then continue.
  - Do not finish a full answer and only then say auth blocked access.
  - Do not loop in-agent `mcp_auth`.
  - Note per-project tokens under `~/.cursor/projects/<project-id>/mcp-auth.json`.
- Delete [`~/.cursor/rules/slack-mcp-auth.mdc`](/home/sungsik/.cursor/rules/slack-mcp-auth.mdc) after the new file exists (content fully absorbed).

### 2. Minimal dotfile pointer rule

- Create [`~/.cursor/rules/dotfiles-agents.mdc`](/home/sungsik/.cursor/rules/dotfiles-agents.mdc) (`alwaysApply: true`), short only:
  - Before changing home/dotfile/agent config (including under `~/.cursor/`), read and follow [`~/.config/AGENTS.md`](/home/sungsik/.config/AGENTS.md).
  - Do not restate work-only / chezmoi details in the rule — those already live in AGENTS.md.

### 3. Track with work chezmoi

Per AGENTS.md: edit live files, then:

```bash
chezmoi --config ~/.config/chezmoi/chezmoi-work.toml add ~/.cursor/rules/mcp-oauth-auth.mdc
chezmoi --config ~/.config/chezmoi/chezmoi-work.toml add ~/.cursor/rules/dotfiles-agents.mdc
# ensure slack-mcp-auth removal is reflected (add/remove as chezmoi expects for deleted live file)
```

Commit and push work chezmoi as `sungsik-nam-vay` unless you ask to skip.