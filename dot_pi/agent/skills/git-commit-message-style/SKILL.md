---
name: git-commit-message-style
description: Apply the user's preferred git commit message style. Use whenever creating or amending git commits for the user, including chezmoi-managed dotfiles commits.
disable-model-invocation: true
---

When creating or amending a git commit for the user, write the commit message according to these rules:

- Start the subject with an imperative verb.
- End the subject with a period.
- Describe what the resulting change does, not what the user or agent did.
- Describe the effect of the change, not just the files touched.
- Keep it concise, but specific enough to explain what the change accomplishes.
- Prefer concrete behavior changes over vague summaries.
- Avoid generic implementation/process verbs like "Update", "Modify", "Refactor", or "Change" when a more specific behavior verb fits.

Examples:

Good:
- `Configure tmux bindings to confirm pane termination.`
- `Reassign tmux split shortcuts to reserve M-x for guarded pane termination.`
- `Omit generated comments from tmuxinator sessions.`
- `Stop adding generated comments to tmuxinator sessions.`

Bad:
- `Update tmux pane keybindings`
- `Update tmuxinator session save script`
- `tmux config`
- `Changed stuff`
- `Configure tmux.`

If a commit body is useful, keep the subject compliant with the rules above and use the body for extra context. The body may be longer, but should still explain the user-visible or operational effect of the change.
