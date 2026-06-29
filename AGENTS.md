# Agent instructions for this home directory

This directory is the user's home directory on Fedora Silverblue, usually accessed from inside a toolbox container.

## Environment

- Host OS: Fedora Silverblue / rpm-ostree immutable desktop.
- Shell environment may be a toolbox container, not the host root filesystem.
- Home path is `/var/home/sungsik`.
- Avoid assuming mutable host OS paths or globally installed host packages.
- Prefer user-scoped changes under `$HOME`, `~/.local`, or managed dotfiles.
- Be careful with commands that affect the host system. If host-level changes are required, explain them first.

## Dotfiles and chezmoi

When an agent is launched from this home directory, assume the task is to modify dotfiles and manage them with chezmoi.

- Chezmoi source directory: `~/.local/share/chezmoi`.
- Prefer editing files in the chezmoi source directory, then applying them with `chezmoi apply`.
- For existing unmanaged home files, use `chezmoi add <path>` before treating them as managed dotfiles.
- If the user says to "manage this change using chezmoi", that means: add/update the file in chezmoi, review with `chezmoi diff` when practical, then commit and push the chezmoi repository.
- Use `chezmoi diff` before applying when practical.
- Do not edit generated/applied dotfiles in `$HOME` directly unless the user explicitly asks or the file is not yet managed.
- Keep secrets out of tracked files. Use chezmoi private/encrypted/ignored mechanisms for sensitive data.

## Project boundaries

- This `AGENTS.md` applies only when working directly in `$HOME` as a dotfiles workspace.
- For normal software projects under `~/Projects` or elsewhere, follow that project's own `AGENTS.md`, README, and repository conventions instead.
- Do not impose home-directory dotfile assumptions on nested projects.

## Fedora Silverblue notes

- Prefer declarative/user-level configuration where possible.
- Package/tool installation may involve toolbox, Flatpak, Home Manager/Nix, or rpm-ostree depending on scope.
- Ask before making broad package-management changes.
