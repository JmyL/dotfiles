# Tool inventory for non-NixOS setup

This checklist is for setting up these dotfiles on a work laptop or other non-NixOS machine. It intentionally lists **external tools to install**, not scripts that are already managed by chezmoi under `~/.local/bin`, and not tmux plugins that TPM installs from `~/.config/tmux/tmux.conf`.

## Assumptions

- Dotfiles are applied with `chezmoi`.
- Custom scripts in `~/.local/bin` come from chezmoi and do not need separate installation.
- tmux plugins are installed by TPM after `tmux` starts; only TPM itself needs manual bootstrap.
- Some desktop tools are only useful on a Wayland/Sway workstation and can be skipped on server/headless setups.

## Must-have CLI/editor stack

These are expected by shell, tmux, vifm, aerc, or general workflows:

- `bash`
- `git`
- `curl`, `wget`
- `chezmoi`
- `nvim`
- `tmux`
- `vifm`
- `fzf` including `fzf-tmux`
- `fd`
- `rg` / ripgrep
- `bat`
- `eza`
- `jq`
- `less`, `man`, `col`
- `zip`, `unzip`, `tar`, `xz`, `7z`
- `starship`
- `zoxide`
- `direnv`
- `atuin`
- `pass`
- `gpg`

## Shell-specific expectations

Config: `~/.bashrc`, `~/.bashrc.d/browser`

- `nvim` is exported as `VISUAL` and `EDITOR`.
- `starship` is initialized with `starship init bash`.
- `zoxide` is initialized with `zoxide init bash`.
- `direnv` hook exists but is currently commented out.
- `fcitx5` environment variables are exported for input method support.
- `toolbox` is referenced by `dv` and `dev-launcher` through `SYSTEM_DEV_TOOLBOX` on Fedora.
- `dnf` is referenced by alias `dnf-backup` on Fedora.
- `sesh`, `tmuxinator`, and `fzf` are referenced by tmux/session aliases.

Expected user-level bin paths:

- `~/.local/bin`
- `~/bin`
- `~/.npm-global/bin`
- `~/go/bin`

## tmux/session tools

Config: `~/.config/tmux/tmux.conf`

Install manually:

- `tmux`
- `fzf`
- `sesh`
- `tmuxinator`
- TPM, the tmux plugin manager

TPM bootstrap:

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

After starting tmux, install plugins with TPM's prefix + `I` binding.

## Desktop/Wayland/Sway stack

Config: `~/.config/sway/config`, `~/.config/waybar/`, `~/.config/kitty/`

Core desktop tools:

- `sway`
- `waybar`
- `kitty`
- `fuzzel`
- `swayidle`
- `swayosd`
- `swaylock`
- `thunar`
- `flatpak`
- Brave Browser as Flatpak app `com.brave.Browser`, or equivalent browser setup
- `wireplumber` (`wpctl`) and `pipewire-bin`/`pipewire-utils` (`pw-dump`) — used by `sway-audio-switch` to list/switch default audio devices

Screenshot/recording/clipboard:

- `grim`
- `grimshot` / sway screenshot helper
- `slurp`
- `swappy`
- `wl-clipboard` (`wl-copy`, `wl-paste`)
- `cliphist`
- `wf-recorder`
- `wtype` — types dictation text into the focused Wayland window
- `pipewire-utils` (`pw-record`) — microphone capture for dictation

Voice dictation:

- `uv`
- `faster-whisper` in the `~/.local/share/sway-dictate/.venv` virtualenv

Notifications/system controls:

- `libnotify` / `notify-send`
- `canberra-gtk-play` for notification sounds
- `swaync-client`
- `swayosd-client`
- `powerprofilesctl`
- `xdg-utils` (`xdg-open`)
- `flatpak-spawn` when using toolbox/container URL opening

Display/input extras:

- `kanshi`
- `fcitx5`
- `fcitx5-hangul` — Hangul input engine; without it fcitx5 silently drops the Hangul entry from `~/.config/fcitx5/profile` on startup

Fonts/integrations:

- `JetBrainsMonoNL Nerd Font Mono`
- `kitty_scrollback_nvim` is handled by Neovim/Kitty plugin setup, not by system package install.

## aerc/mail stack

Config: `~/.config/aerc/`

Current IMAP/aerc setup:

- `aerc`
- `nvim`
- `pass`
- `gpg`
- `notify-send`
- `pandoc`
- `zathura`
- `vimiv`
- `vlc`

Planned local mail/notmuch migration, documented in `~/.config/aerc/notmuch-migration.md`:

- `isync` / `mbsync`
- `notmuch`

Calendar/contact integration, documented in `~/.config/calendar-contacts-vdirsyncer.md`:

- `vdirsyncer`
- `khal`
- `khard`

## vifm helper tools

Config: `~/.config/vifm/vifmrc`

Core:

- `vifm`
- `nvim`
- `tmux`
- `wl-clipboard`

Preview/open helpers referenced by config:

- `poppler-utils` / `pdftotext`
- `mp3info`
- `sox` / `soxi`
- `links` or `lynx`
- `binutils` / `nm`
- `transmission`
- `dumptorrent`
- `vlc` — video opener
- `ffprobe` / FFmpeg — video metadata preview
- `unrar`
- `p7zip` / `7z`
- `catdoc`
- `docx2txt`
- `tudu`
- `xclip` for legacy/fallback clipboard mappings
- `nautilus` and `xterm` for legacy mappings; optional if not used

## Coding-agent / optional user tools

These are useful for reproducing the full environment but may be installed by their own upstream installers rather than OS packages:

- `pi`
- `herdr`
- `uv`, `uvx`
- `gh`
- `act`
- `k6`
- `zellij`
- `tuxedo`
- `pop-launcher`

## Fedora install command

This is the broad workstation-oriented install set. Some packages may vary by Fedora release or repositories.

```sh
sudo dnf install \
  aerc atuin bat binutils catdoc chezmoi cliphist curl direnv dnf-plugins-core \
  docx2txt eza fcitx5 fcitx5-hangul fd-find ffmpeg-free flatpak fuzzel fzf git gnupg2 grim \
  grimshot isync jq kanshi kitty less libcanberra-gtk3 libnotify links lynx man-db \
  mp3info neovim notmuch pandoc pass p7zip p7zip-plugins poppler-utils \
  power-profiles-daemon ripgrep slurp sox starship swappy sway swayidle \
  khal khard vdirsyncer \
  swaylock thunar tmux transmission unrar vifm vimiv vlc waybar wf-recorder \
  wl-clipboard wtype xclip xdg-utils xterm zathura zip zoxide wireplumber pipewire-utils
```

Fedora follow-ups:

```sh
# tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Brave browser, if using the Flatpak app expected by sway config
flatpak install flathub com.brave.Browser
```

May need separate installation depending on Fedora version/repositories:

- `swayosd-client`
- `swaync-client`
- `sesh`
- `tmuxinator`
- `pi`
- `herdr`
- `uv`
- `JetBrainsMonoNL Nerd Font Mono`

## Ubuntu install command

Test/package names may vary by Ubuntu release. This is aimed at recent Ubuntu versions.

```sh
sudo apt update
sudo apt install \
  aerc atuin bat binutils catdoc cliphist curl direnv docx2txt eza fcitx5 fcitx5-hangul \
  fd-find ffmpeg flatpak fuzzel fzf git gnupg grim isync jq kanshi kitty less \
  libcanberra-gtk3-bin libnotify-bin links lynx man-db mp3info neovim notmuch p7zip-full \
  p7zip-rar pandoc pass poppler-utils power-profiles-daemon ripgrep \
  khal khard vdirsyncer \
  slurp sox starship swappy sway swayidle swaylock swayosd thunar tmux \
  transmission-cli unrar vifm vimiv vlc waybar wf-recorder wl-clipboard \
  wtype xclip xdg-utils xterm zathura zip zoxide grimshot build-essential libreadline-dev unzip \
  python3-venv imagemagick lazygit luarocks wireplumber pipewire-bin
```

Ubuntu follow-ups:

```sh
# chezmoi if the Ubuntu package is too old or unavailable
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"

# tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Ubuntu packages that may be missing, renamed, too old, or better installed another way:

- npm install -g @mermaid-js/mermaid-cli
- brave-browser
- `grimshot` may come from `sway-contrib` or need a manual install depending on release.
- `swayosd-client`
- `swaync-client`
- `sesh`: go install github.com/joshmedeski/sesh/v2@latest
- `tmuxinator`
- `pi`
- `herdr`
- `uv`
- `dumptorrent`
- `tudu`
- `JetBrainsMonoNL Nerd Font Mono`
- fonts-font-awesome

## Minimal non-desktop/server install

For a terminal-only setup without Sway/Waybar desktop pieces:

```sh
# Fedora
sudo dnf install \
  aerc bat binutils chezmoi curl direnv eza fd-find fzf git gnupg2 isync \
  jq kitty less man-db neovim notmuch pandoc pass p7zip p7zip-plugins \
  poppler-utils ripgrep starship tmux vifm wl-clipboard xdg-utils zathura \
  khal khard vdirsyncer \
  zip zoxide go

# Ubuntu
sudo apt update
sudo apt install \
  aerc bat binutils curl direnv eza fd-find fzf git gnupg isync jq kitty \
  less man-db neovim notmuch p7zip-full pandoc pass poppler-utils ripgrep \
  starship tmux vifm wl-clipboard xdg-utils zathura khal khard vdirsyncer \
  zip zoxide go
```
