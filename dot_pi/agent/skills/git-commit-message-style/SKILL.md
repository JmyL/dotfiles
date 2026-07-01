---
name: git-commit-message-style
description: Apply the user's preferred git commit message style. Use whenever creating or amending git commits for the user, including chezmoi-managed dotfiles commits.
disable-model-invocation: true
---

When creating or amending a git commit for the user, follow Chris Beams' seven rules, with emphasis on describing the resulting behavior rather than the editing process.

## Seven rules

1. Separate subject from body with a blank line.
2. Limit the subject line to about 50 characters when practical.
3. Capitalize the subject line.
4. Do not end the subject line with a period.
5. Use the imperative mood in the subject line.
6. Wrap the body at 72 characters when writing one.
7. Use the body to explain what and why, not how.

## User preference

- Describe what the resulting change does, not what the user or agent did.
- Prefer concrete behavior changes over vague summaries.
- Avoid generic implementation/process verbs like "Update", "Modify", "Refactor", or "Change" when a more specific behavior verb fits.
- A good subject should fit: "If applied, this commit will <subject>".

Examples:

Good:
- `Configure tmux bindings to confirm pane termination`
- `Reassign tmux split shortcuts to preserve M-x`
- `Omit generated comments from tmuxinator sessions`
- `Stop adding generated comments to tmuxinator sessions`

Bad:
- `Update tmux pane keybindings`
- `Update tmuxinator session save script`
- `tmux config`
- `Changed stuff`
- `Configure tmux.`
