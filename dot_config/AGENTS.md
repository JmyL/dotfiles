# Agent instructions for this home directory

This directory is the user's home directory, with the same chezmoi dotfiles applied across more than one machine. The host environment differs by machine — check which kind you're on before assuming host paths or package-management behavior.

## Environment

Two host kinds are in use:

- **Fedora Silverblue (rpm-ostree, immutable)**: usually accessed from inside a toolbox container, not the host root filesystem — check `cat /run/.containerenv` (present inside a toolbox) to tell. Home path is `/var/home/sungsik`. Avoid assuming mutable host OS paths or globally installed host packages; prefer user-scoped changes under `$HOME`, `~/.local`, or managed dotfiles. Be careful with commands that affect the host system — if host-level (rpm-ostree/toolbox) changes are required, explain them first. See "Fedora Silverblue notes" below.
- **Mutable Debian/Ubuntu (e.g. work laptop)**: a regular mutable install, no toolbox layer — the shell is the host directly. Home path is `/home/sungsik`. `apt`/`dpkg` can be used directly for host package changes, but still ask before broad or system-wide package-management changes.

To tell which one you're on: `cat /etc/os-release` (`ID=fedora` vs `ID=ubuntu`/`ID_LIKE=debian`), and `echo $HOME` (`/var/home/...` vs `/home/...`). Don't assume from a prior session — check fresh each time, since the same dotfiles repo is applied to both.

## Dotfiles and chezmoi

When an agent is launched from this home directory, assume the task is to modify dotfiles and manage them with chezmoi.

- Personal chezmoi source: `~/.local/share/chezmoi` (repo `JmyL/dotfiles`).
- Work chezmoi source: `~/.local/share/chezmoi-work` (private repo `sungsik-nam-vay/dotfiles-work`), config `~/.config/chezmoi/chezmoi-work.toml`. Apply after personal: `chezmoi --config ~/.config/chezmoi/chezmoi-work.toml apply`. Work paths live under `~/.config/work/` and `~/.local/bin/work/`.
- **Cursor is work-only.** Do not track Cursor config under personal chezmoi. Manage `~/.cursor/` (e.g. `mcp.json`, `rules/`) with work chezmoi (`chezmoi --config ~/.config/chezmoi/chezmoi-work.toml add …`). Leave secrets and local state untracked (`~/.config/cursor/auth.json`, `chats/`, `projects/`, `mcp-auth.json`, caches). Cursor Agent CLI (`agent`) is company-machine only; personal machines should keep using `claude` / `codex` / `pi` via `ai` fallback. Exception: personal chezmoi tracks `~/.cursor/plans` as a symlink to `~/.config/plans` so Cursor’s plan UI keeps working.
- **Deferred agent plans:** Not Obsidian. Personal / home-infra plans → `~/.config/plans/` (personal chezmoi: `chezmoi add ~/.config/plans/…`). Company / work-machine plans → `~/.config/work/plans/` (work chezmoi: `chezmoi --config ~/.config/chezmoi/chezmoi-work.toml add …`). Prefer those paths when editing; `~/.cursor/plans` is only the Cursor UI symlink to `~/.config/plans` (personal plans).
- Tmuxinator: if the YAML `root` is under `$HOME/projects`, the session goes to `~/.config/work/tmuxinator/` plus a symlink under `~/.config/tmuxinator/` (via `tmuxinator-chezmoi` and the new/save/delete wrappers). Otherwise it stays in personal chezmoi. Deletes update that repo's `.chezmoiremove` for cross-machine cleanup. Name prefixes like `ree-*` are not used for routing.
- Herdr-plus projects: if `working_dir` is under `$HOME/projects`, the TOML goes to `~/.config/work/herdr-plus/projects/` plus a symlink under `~/.config/herdr/plugins/config/cloudmanic.herdr-plus/projects/` (via `herdr-plus-chezmoi`). Otherwise the file lives directly in the herdr-plus projects dir under personal chezmoi.
- Prefer editing the live dotfile in `$HOME` first, then run `chezmoi add <path>` (or `chezmoi --config ~/.config/chezmoi/chezmoi-work.toml add <path>` for work files) to update the matching chezmoi source from the live file.
- For existing unmanaged home files, use `chezmoi add <path>` after making or verifying the desired live-file change.
- When summarizing or managing pending chezmoi changes, always check **live ↔ source** with `chezmoi status` / `chezmoi diff`, plus the work equivalents (`chezmoi --config ~/.config/chezmoi/chezmoi-work.toml status` / `diff`). Do **not** rely only on `git status` in `~/.local/share/chezmoi` or `chezmoi-work` — that misses destination drift that is not yet reflected in the source git tree.
- Interpret `chezmoi diff` as **apply direction** (what would change in the live destination if source were applied). If the live file is ahead, `chezmoi add` then commit/push. If the source is ahead (e.g. after pull, or an unapplied source edit), `chezmoi apply` the path instead of adding the stale live file over source. Mode-only noise can be cleared with apply or left alone; do not commit permission churn unless intentional.
- For dotfile changes in this home workspace, treat the full default workflow as: edit the live dotfile, run `chezmoi add <path>`, review with `chezmoi diff` when practical, then commit the chezmoi repository and push. Do this for normal dotfile change requests, not only when the user explicitly says "manage". Skip the commit only when the user asks not to commit, asks to inspect/test only, or the change is intentionally incomplete. Push automatically after every commit to this repo, without waiting to be asked; skip the push only if the user says not to, or the commit is intentionally incomplete/local-only.
- Push personal chezmoi as `JmyL`; push work chezmoi as `sungsik-nam-vay` (`gh auth switch --user ...` if needed). On Fedora Silverblue, push the personal chezmoi repository through `~/.local/bin/dev-launcher git -C ~/.local/share/chezmoi push` so the command runs in the toolbox environment with the available GitHub credentials. Direct host pushes may fail because the host lacks `gh` or network/credential access.
- Use `chezmoi diff` after `chezmoi add` when practical to review what will be tracked.
- Do not edit files in `~/.local/share/chezmoi` (or `chezmoi-work`) directly for normal dotfile changes unless the user explicitly asks, the live file cannot be safely edited, or a chezmoi template/source-only file requires direct source edits.
- Keep secrets out of tracked files. Use chezmoi private/encrypted/ignored mechanisms for sensitive data.
- For tmux status-bar confirmations, prefer tmux-native `confirm-before` with `y/n` prompts unless an explicit default-on-Enter behavior is required.

## Sway / Waybar

Waybar is started only by Sway's `bar { swaybar_command …/waybar-sway-bar }` block in `~/.config/sway/config.d/05-waybar-bar.conf` (wrapper runs `waybar -b bar-0` and restarts on exit; path must be absolute because Sway does not expand `~`/`$HOME` in `swaybar_command`). Do not also `swaymsg exec waybar` (or equivalent): that leaves an unmanaged second instance that survives `swaymsg reload` and stacks with the bar-managed one.

- CSS/config-only changes: `swaymsg reload` is enough.
- If Waybar must be restarted: `killall waybar; swaymsg reload` — never `swaymsg exec waybar`.

## Herdr plugins

When changing Herdr plugin behavior, keybindings, or local plugin repos, check the cross-machine install path before finishing.

- `~/.config/herdr/plugins.list` is the declarative list consumed by `~/.local/bin/herdr-install-plugins`. Lines are `<github-repo> [ref]`; refs can be branches or tags.
- Local `herdr plugin link ...` is for development on the current machine only. For changes that must reach other PCs, push the plugin repo branch/tag referenced in `plugins.list`.
- If a plugin change requires a different repo/ref, update the live `~/.config/herdr/plugins.list`, run `chezmoi add ~/.config/herdr/plugins.list`, review `chezmoi diff`, then commit and push the dotfiles repo.
- If the plugin installer script changes, edit `~/.local/bin/herdr-install-plugins`, run `bash -n ~/.local/bin/herdr-install-plugins`, then manage it with `chezmoi add ~/.local/bin/herdr-install-plugins`.

## Shell script formatting

Neovim formats shell with `shfmt -i 2` (conform). Write bash that already matches that style so format-on-save is a no-op:

- Two-space indent (not tabs).
- No spaces inside arithmetic: `((x))`, not `(( x ))`.
- In `case` arms, align patterns with the `case` keyword (do not indent them further); put spaces around `|` in pattern lists (`claude | agent | pi`).

## Neovim plugin updates (lazy.nvim)

`~/.config/nvim` is its own git repository. Prefer infrequent, intentional plugin updates over habitual `:Lazy sync`.

- After updating plugins, commit `lazy-lock.json` together with any related config changes under `~/.config/nvim` in the same commit, so a working pair of lock + config can be restored together.
- If an update breaks Neovim, restore the previous lock (and config) rather than debugging against a mixed state.

## Tool inventory

When adding or modifying dotfiles that introduce a dependency on an external command, check `~/.config/tool-inventory.md`.

- If the tool is already listed, no extra action is needed.
- If the tool is not listed and is expected to be installed manually on a new machine, add it to `~/.config/tool-inventory.md`.
- Do not list scripts managed by chezmoi under `~/.local/bin`; those come from the dotfiles themselves.
- Do not list tmux plugins installed by TPM; list TPM itself and external commands used by tmux config/scripts.
- When practical, update the Fedora and Ubuntu install command sections in `~/.config/tool-inventory.md`.

## Obsidian

- Vault rules live in `~/Documents/Obsidian/AGENTS.md`. Follow that file when working in the vault.
- **Do not modify daily notes** (`YYYY-MM-DD.md`) unless the user explicitly asks, **except** when creating a new issue-analysis note (then append under `## Issues`). Reading today’s note for context is fine. See vault `AGENTS.md` and skill `obsidian-issue-analysis`.
- New notes: create via Neovim `ObsidianNew` (see vault `AGENTS.md` / Cursor rule `obsidian-notes.mdc`); never hand-write zettel ids.
- Do not put agent/infra implementation plans in Obsidian; use `~/.config/plans/` (personal) or `~/.config/work/plans/` (company).

## Project boundaries

- This `AGENTS.md` applies only when working directly in `$HOME` as a dotfiles workspace.
- For normal software projects under `~/Projects` or elsewhere, follow that project's own `AGENTS.md`, README, and repository conventions instead.
- Do not impose home-directory dotfile assumptions on nested projects.

## Fedora Silverblue notes

- Prefer declarative/user-level configuration where possible.
- Package/tool installation may involve toolbox, Flatpak, Home Manager/Nix, or rpm-ostree depending on scope.
- Ask before making broad package-management changes.

## Mutable Debian/Ubuntu notes

- No toolbox/rpm-ostree layer — `apt`/`dpkg` install packages directly on the host.
- Package availability and naming can differ from Fedora (e.g. `~/.config/tool-inventory.md`'s Fedora vs Ubuntu install sections) — check both when a dependency isn't found.
- Ask before making broad or system-wide package-management changes, same caution as Silverblue's host-level changes.
