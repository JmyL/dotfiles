# Tool inventory for non-NixOS setup

This is a practical checklist of tools referenced by the current dotfiles. It is intended for setting up a work laptop or other non-NixOS/Fedora-Silverblue machine where Home Manager is not available.

## Core terminal/editor stack

- `bash` — shell config is managed in `~/.bashrc` and `~/.bashrc.d/`.
- `nvim` — primary editor; config in `~/.config/nvim`.
- `kitty` — terminal emulator; config in `~/.config/kitty/kitty.conf`.
- `tmux` — terminal multiplexer; config in `~/.config/tmux/tmux.conf`.
- `vifm` — terminal file manager; config in `~/.config/vifm/vifmrc`.
- `starship` — shell prompt; config in `~/.config/starship.toml`.
- `zoxide` — directory jumper, referenced by tmux/sesh workflows.
- `direnv` — per-directory environment loader.

Useful CLI utilities commonly expected by configs/workflows:

- `git`
- `fd`
- `rg` / ripgrep
- `fzf` and `fzf-tmux`
- `bat`
- `eza`
- `jq`
- `curl`
- `wget`
- `unzip`, `zip`, `tar`, `xz`, `7z`
- `man`, `col`, `less`

## Dotfile/bootstrap tools

- `chezmoi` — dotfile manager.
- `pass` — password store for mail credentials.
- `gpg` — required by `pass`.
- `pi` — coding agent CLI/config under `~/.pi` / `~/.config/.pi`.
- `herdr` — terminal workspace/session tool.

## tmux ecosystem

Config: `~/.config/tmux/tmux.conf`

Required/referenced tools:

- `tmux`
- `tpm` — tmux plugin manager, configured through TPM in tmux config.
- `tmux-plugins/tmux-sensible`
- `Morantron/tmux-fingers`
- `mrjones2014/smart-splits.nvim`
- `omerxx/tmux-floax`
- `tmux-plugins/tmux-yank`
- `tmux-plugins/tmux-cpu`
- `tmux-plugins/tmux-battery`
- `catppuccin/tmux`
- `fzf`, `fzf-tmux`
- `sesh`
- `tmuxinator`
- custom scripts in `~/.local/bin`:
  - `swap-pane-direction`
  - `tmux-kill-current-session`
  - `tmuxinator-edit-session`
  - `tmuxinator-project-list`
  - `tmuxinator-project-action`
  - `tmuxinator-project-preview`
  - `tmuxinator-save-session-notify`

## Wayland/Sway desktop stack

Config: `~/.config/sway/config`

Core:

- `sway`
- `waybar`
- `kitty`
- `fuzzel`
- `swayidle`
- `swaylock`
- `swaymsg`
- `thunar`
- `flatpak` + Brave browser app ID `com.brave.Browser`

Screenshots/recording/clipboard:

- `grim`
- `grimshot`
- `swappy`
- `wl-clipboard` (`wl-copy`, `wl-paste`)
- `cliphist`
- custom scripts:
  - `save-screenshot`
  - `sway-recording`

System controls/notifications:

- `swayosd-client`
- `swaync-client`
- `powerprofilesctl`
- custom scripts:
  - `toggle-idle-inhibit`
  - `idle-inhibited`
  - `idle-inhibit-status`
  - `cycle-power-profile`
  - `sway-toggle-external-extend`

Display/input extras tracked in dotfiles:

- `kanshi` — config in `~/.config/kanshi/config`.
- `fcitx5` — config under `~/.config/fcitx5`.

## Waybar

Config: `~/.config/waybar/config.jsonc`, `~/.config/waybar/style.css`

Referenced custom commands/scripts:

- `~/.local/bin/idle-inhibit-status`
- `~/.local/bin/sway-recording status`
- `~/.config/waybar/mediaplayer.py` if used later
- `~/.config/waybar/power_menu.xml` if using menu actions

## Kitty

Config: `~/.config/kitty/kitty.conf`

Notable dependencies:

- Font: `JetBrainsMonoNL Nerd Font Mono`
- `kitty_scrollback_nvim` integration
- `nvim`
- `open_url_with_hints`

## aerc/mail stack

Config: `~/.config/aerc/`

Required/current:

- `aerc`
- `nvim`
- `pass`
- `gpg`
- `notify-send`
- `pandoc` — HTML-to-text filter
- `zathura` — PDF opener
- `vimiv` — image opener
- custom script:
  - `aerc-open-nvim`

For planned local mail/notmuch migration, see `~/.config/aerc/notmuch-migration.md`:

- `isync` / `mbsync`
- `notmuch`

## vifm file-manager stack

Config: `~/.config/vifm/vifmrc`

Core:

- `vifm`
- `nvim`
- `tmux`
- `wl-copy` / `wl-clipboard`
- custom script: `clipwrite`

Preview/open helpers referenced by config:

- `pdftotext` — PDF preview
- `mp3info` — MP3 metadata preview
- `soxi` — FLAC/audio metadata preview
- `links` or `lynx` — HTML viewing
- `nm`, `less`, `man`, `col` — object/man page viewing
- `transmission` — torrent opener
- `dumptorrent` — torrent preview
- `zip`
- `tar`
- `xz`
- `unrar`
- `7z`
- `catdoc`
- `docx2txt.pl`
- `tudu`
- legacy/fallback clipboard tools in config: `xclip`
- legacy GUI file managers/terminals referenced in old mappings: `nautilus`, `xterm`

## Document/PDF/image tools

- `zathura`
- `vimiv`
- `pandoc`
- `pdftotext`
- `swappy`

## Custom scripts managed in dotfiles

Tracked under `~/.local/bin` via chezmoi:

- `aerc-open-nvim`
- `clipwrite`
- `cycle-power-profile`
- `idle-inhibit-status`
- `idle-inhibited`
- `install-dropbox-tray-icons`
- `open-url`
- `prompt-ui`
- `save-screenshot`
- `swap-pane-direction`
- `sway-recording`
- `sway-toggle-external-extend`
- `tmux-kill-current-session`
- `tmux-popup-ui`
- `tmuxinator-edit-session`
- `tmuxinator-new-popup`
- `tmuxinator-new-session`
- `tmuxinator-project-action`
- `tmuxinator-project-list`
- `tmuxinator-project-preview`
- `tmuxinator-save-session`
- `tmuxinator-save-session-notify`
- `toggle-idle-inhibit`

## Fedora package name hints

Approximate Fedora package names for many external tools:

```sh
sudo dnf install \
  aerc bat direnv eza fd-find fzf git gnupg2 isync jq kitty less man-db \
  neovim notmuch pass pandoc poppler-utils ripgrep starship sway swayidle \
  swaylock thunar tmux vifm waybar wl-clipboard zathura zip p7zip p7zip-plugins
```

Some tools may need COPR, cargo/go install, Flatpak, or manual installation depending on the machine:

- Brave Browser: Flatpak `com.brave.Browser` or vendor repo.
- `sesh`: often installed via Go/Cargo/project release.
- `herdr`, `pi`: user-level installers.
- `tmuxinator`: Ruby gem or package.
- `swayosd-client`, `swaync-client`, `cliphist`, `grimshot`, `swappy`, `vimiv`, `kanshi`, `fcitx5`: package availability varies by distro/release.
- `kitty_scrollback_nvim`: Neovim/Kitty integration, usually installed through Neovim plugin setup.
