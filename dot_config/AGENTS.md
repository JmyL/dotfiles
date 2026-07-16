# Agent instructions for this home directory

This directory is the user's home directory, with the same chezmoi dotfiles applied across more than one machine. The host environment differs by machine — check which kind you're on before assuming host paths or package-management behavior.

## Environment

Two host kinds are in use:

- **Fedora Silverblue (rpm-ostree, immutable)**: usually accessed from inside a toolbox container, not the host root filesystem — check `cat /run/.containerenv` (present inside a toolbox) to tell. Home path is `/var/home/sungsik`. Avoid assuming mutable host OS paths or globally installed host packages; prefer user-scoped changes under `$HOME`, `~/.local`, or managed dotfiles. Be careful with commands that affect the host system — if host-level (rpm-ostree/toolbox) changes are required, explain them first. See "Fedora Silverblue notes" below.
- **Mutable Debian/Ubuntu (e.g. work laptop)**: a regular mutable install, no toolbox layer — the shell is the host directly. Home path is `/home/sungsik`. `apt`/`dpkg` can be used directly for host package changes, but still ask before broad or system-wide package-management changes.

To tell which one you're on: `cat /etc/os-release` (`ID=fedora` vs `ID=ubuntu`/`ID_LIKE=debian`), and `echo $HOME` (`/var/home/...` vs `/home/...`). Don't assume from a prior session — check fresh each time, since the same dotfiles repo is applied to both.

## Dotfiles and chezmoi

When an agent is launched from this home directory, assume the task is to modify dotfiles and manage them with chezmoi.

- Chezmoi source directory: `~/.local/share/chezmoi`.
- Prefer editing the live dotfile in `$HOME` first, then run `chezmoi add <path>` to update the chezmoi source from the live file.
- For existing unmanaged home files, use `chezmoi add <path>` after making or verifying the desired live-file change.
- For dotfile changes in this home workspace, treat the full default workflow as: edit the live dotfile, run `chezmoi add <path>`, review with `chezmoi diff` when practical, then commit the chezmoi repository and push. Do this for normal dotfile change requests, not only when the user explicitly says "manage". Skip the commit only when the user asks not to commit, asks to inspect/test only, or the change is intentionally incomplete. Push automatically after every commit to this repo, without waiting to be asked; skip the push only if the user says not to, or the commit is intentionally incomplete/local-only.
- Use `chezmoi diff` after `chezmoi add` when practical to review what will be tracked.
- Do not edit files in `~/.local/share/chezmoi` directly for normal dotfile changes unless the user explicitly asks, the live file cannot be safely edited, or a chezmoi template/source-only file requires direct source edits.
- Keep secrets out of tracked files. Use chezmoi private/encrypted/ignored mechanisms for sensitive data.
- For tmux status-bar confirmations, prefer tmux-native `confirm-before` with `y/n` prompts unless an explicit default-on-Enter behavior is required.

## Tool inventory

When adding or modifying dotfiles that introduce a dependency on an external command, check `~/.config/tool-inventory.md`.

- If the tool is already listed, no extra action is needed.
- If the tool is not listed and is expected to be installed manually on a new machine, add it to `~/.config/tool-inventory.md`.
- Do not list scripts managed by chezmoi under `~/.local/bin`; those come from the dotfiles themselves.
- Do not list tmux plugins installed by TPM; list TPM itself and external commands used by tmux config/scripts.
- When practical, update the Fedora and Ubuntu install command sections in `~/.config/tool-inventory.md`.

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
