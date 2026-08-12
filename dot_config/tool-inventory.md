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
- `delta` (`git-delta` package; configured as git pager in `~/.gitconfig`)
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
- `git` uses `delta` as pager (`core.pager` in `~/.gitconfig`).
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
- `foot` — fast floating terminal for `fzf-menu` / `fzf-drun` / `clipse` (font matched to kitty). Ubuntu 26.04 apt is 1.25 (no `[colors-dark]`); build ≥1.26 to `~/.local` from https://codeberg.org/dnkl/foot/releases
- `fzf` — used by floating `fzf-menu` / `fzf-drun` pickers (replaces fuzzel)
- `swayidle`
- `swayosd`
- `swaylock`
- `thunar`
- `flatpak`
- Brave Browser as Flatpak app `com.brave.Browser`, or equivalent browser setup (still used for packing local extensions / optional browsing)
- Vivaldi (`vivaldi-stable`) — Sway `$mod+Shift+i` default browser on this setup
- Vivaldi UI pack: `~/.config/vivaldi-ui/` (chezmoi) — `active-tab.css` (strong active-tab highlight), `layout.json` (toolbar composition, hidden extension toolbar icons, tab/address bar bottom, native window). Apply with `vivaldi-setup-ui` while Vivaldi is quit (sets Custom UI Modifications path + merges `layout.json` into Preferences). Do **not** track `~/.config/vivaldi/` profile state.
- Tampermonkey (Brave/Chrome/Vivaldi extension) — runs userscripts under `~/.config/userscripts/` (e.g. `circleci-tab-status.user.js`). Install/update by opening the `.user.js` file in the browser or pasting into Tampermonkey → Create a new script.
- Local Chromium extension `~/.local/share/brave-extensions/slack-stay-in-browser` — rewrites Slack `archives` permalinks to `messages` so they open in the web client without the desktop-app prompt; Alt+S focuses an open Slack tab (`vivaldi://extensions/shortcuts` / `brave://extensions/shortcuts`). Pack/register with `brave-install-local-extensions` (writes `.crx`/`.pem` under `~/.local/state/brave-extensions/` and External Extensions JSON for both Brave and Vivaldi). Restart the browser fully after installing or upgrading on a new machine.

Vivaldi UI checklist (new machine):

1. Install `vivaldi-stable`, then once: `brave-install-local-extensions` and fully restart Vivaldi (Slack stay-in-browser).
2. Quit Vivaldi, run `vivaldi-setup-ui`, start Vivaldi — CSS + toolbar/hidden icons + bar positions from `vivaldi-ui/layout.json`.
3. After changing toolbars or “Hide button” on an extension icon in the UI, copy the new `toolbars.*` / `address_bar.extensions.hidden_extensions` values into `~/.config/vivaldi-ui/layout.json`, then `chezmoi add` that file.
4. Themes: prefer a **user copy** of Dark; Coloring mode **not Unified** (`layout.json` sets `theme_color_position=addressbar` on the scheduled theme). Stock theme edits can reset on update.
5. Auto-Hide: optional; address bar only if used. Unified + Auto-Hide can leave a frame.
6. Confirm `vivaldi://extensions` has Slack stay-in-browser; shortcuts: Alt+S for Slack tab focus. Hidden toolbar icons (Show Tab Numbers, Slack stay-in-browser) still run in the background.
- `wireplumber` (`wpctl`) and `pipewire-bin`/`pipewire-utils` (`pw-dump`) — used by `sway-audio-switch` to list/switch default audio devices

Screenshot/recording/clipboard:

- `grim`
- `grimshot` / sway screenshot helper
- `slurp`
- `swappy`
- `wl-clipboard` (`wl-copy`, `wl-paste`)
- `clipse` — clipboard history TUI (`$mod+v`); install Wayland amd64 release to `~/.local/bin/clipse`. **autoPaste** on Wayland needs `/dev/uinput` access: run `~/.local/bin/clipse-setup-uinput` on each machine (idempotent; uses sudo). Check with `clipse-setup-uinput --check`. On Fedora Silverblue/toolbox, run it on the **host**. Then **log out and back in** so group `input` is active in the session.
- `wf-recorder`
- `wtype` — types dictation text into the focused Wayland window
- `pipewire-utils` (`pw-record`) — microphone capture for dictation

Voice dictation:

- `uv`
- `faster-whisper` in the `~/.local/share/sway-dictate/.venv` virtualenv

Notifications/system controls:

- `libnotify` / `notify-send` (aerc and other callers; herdr-focus-notify uses D-Bus via `python3-gi` instead)
- `python3-gi` (PyGObject) — required by `herdr-focus-notify`'s `scripts/linux-notify-wait.py`
- `canberra-gtk-play` for notification sounds
- `swaync-client`
- `swayosd-client`
- `blueman` (`blueman-applet`, `blueman-manager`) — applet is started from `~/.config/sway/config.d/20-blueman.conf` so manager does not cold-start it
- `powerprofilesctl`
- `xdg-utils` (`xdg-open`)
- `flatpak-spawn` when using toolbox/container URL opening

Display/input extras:

- `kanshi`
- `fcitx5`
- `fcitx5-hangul` — Hangul input engine; without it fcitx5 silently drops the Hangul entry from `~/.config/fcitx5/profile` on startup

Fonts/integrations:

- `JetBrainsMonoNL Nerd Font Mono` — Kitty / terminals
- `JetBrainsMonoNL Nerd Font` — Waybar (from Nerd Fonts `JetBrainsMono.tar.xz` into `~/.local/share/fonts`; install `JetBrainsMonoNLNerdFont-*.ttf`, not Mono/Propo)
- `ShureTechMono Nerd Font Mono` — Nerd Fonts packaging of Share Tech Mono (install under `~/.local/share/fonts`)
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
- `bun` (needed by some Herdr plugins, e.g. `danbuhler/herdr-pane-topic-sync`)
- `uv`, `uvx`
- `gh`
- `gh` extension `dlvhdr/gh-dash` (`gh extension install dlvhdr/gh-dash`)
- `gh-review` — line-level PR review TUI used from gh-dash (`R`); `cargo install gh-review`
- `act`
- `k6`
- `zellij`
- `tuxedo`
- `pop-launcher`

## Fedora install command

This is the broad workstation-oriented install set. Some packages may vary by Fedora release or repositories.

```sh
sudo dnf install \
  aerc atuin bat binutils blueman catdoc chezmoi curl direnv dnf-plugins-core \
  docx2txt eza fcitx5 fcitx5-hangul fd-find ffmpeg-free flatpak foot fzf git git-delta gnupg2 grim \
  grimshot isync jq kanshi kitty less libcanberra-gtk3 libnotify links lynx man-db \
  mp3info neovim notmuch pandoc pass p7zip p7zip-plugins poppler-utils python3-gobject \
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
- `bun` — `curl -fsSL https://bun.sh/install | bash` (symlink `~/.bun/bin/bun` into `~/.local/bin` if Herdr's PATH lacks `~/.bun/bin`)
- `uv`
- `gh` extension `dlvhdr/gh-dash`: `gh extension install dlvhdr/gh-dash`
- `gh-review`: `cargo install gh-review`
- `JetBrainsMonoNL Nerd Font Mono`
- `JetBrainsMonoNL Nerd Font` — Waybar (`curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz | tar -xJ -C ~/.local/share/fonts --wildcards 'JetBrainsMonoNLNerdFont-*.ttf' && fc-cache -f ~/.local/share/fonts`)
- `clipse` (Wayland release tarball → `~/.local/bin/clipse`):
  `curl -fsSL https://github.com/savedra1/clipse/releases/download/v1.2.1/clipse_v1.2.1_linux_wayland_amd64.tar.gz | tar -xz -C /tmp && install -m 755 /tmp/clipse-linux-wayland-amd64 ~/.local/bin/clipse`
- `clipse-setup-uinput` (chezmoi-managed under `~/.local/bin`) after installing clipse:
  `clipse-setup-uinput` then re-login; verify with `clipse-setup-uinput --check`

## Ubuntu install command

Test/package names may vary by Ubuntu release. This is aimed at recent Ubuntu versions.

```sh
sudo apt update
sudo apt install \
  aerc atuin bat binutils blueman catdoc curl direnv docx2txt eza fcitx5 fcitx5-hangul \
  fd-find ffmpeg flatpak foot fzf git git-delta gnupg grim isync jq kanshi kitty less \
  libcanberra-gtk3-bin libnotify-bin links lynx man-db mp3info neovim notmuch p7zip-full \
  p7zip-rar pandoc pass poppler-utils power-profiles-daemon ripgrep \
  khal khard vdirsyncer \
  slurp sox starship swappy sway swayidle swaylock swayosd thunar tmux \
  transmission-cli unrar vifm vimiv vlc waybar wf-recorder wl-clipboard \
  wtype xclip xdg-utils xterm zathura zip zoxide grimshot build-essential libreadline-dev unzip \
  python3-venv python3-gi imagemagick lazygit luarocks wireplumber pipewire-bin
```

Ubuntu follow-ups:

```sh
# chezmoi if the Ubuntu package is too old or unavailable
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"

# tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Ubuntu packages that may be missing, renamed, too old, or better installed another way:

- `foot` ≥1.26 (Ubuntu 26.04 apt is 1.25): build to `~/.local` — `sudo apt install meson ninja-build libwayland-dev wayland-protocols libxkbcommon-dev libfontconfig-dev libfreetype-dev libpixman-1-dev libfcft-dev libtllist-dev libutf8proc-dev libutempter-dev scdoc` then from the [release tarball](https://codeberg.org/dnkl/foot/releases): `meson setup build --buildtype=release --prefix="$HOME/.local" && ninja -C build install`
- npm install -g @mermaid-js/mermaid-cli
- brave-browser (still used to pack local `.crx` via `brave-install-local-extensions`)
- vivaldi-stable (Sway `$mod+Shift+i`; install from Vivaldi’s apt repo or package)
- `grimshot` may come from `sway-contrib` or need a manual install depending on release.
- `swayosd-client`
- `swaync-client`
- `sesh`: go install github.com/joshmedeski/sesh/v2@latest
- `tmuxinator`
- `pi`
- `herdr`
- `bun` — `curl -fsSL https://bun.sh/install | bash` (symlink `~/.bun/bin/bun` into `~/.local/bin` if Herdr's PATH lacks `~/.bun/bin`)
- `uv`
- `gh` extension `dlvhdr/gh-dash`: `gh extension install dlvhdr/gh-dash`
- `gh-review`: `cargo install gh-review`
- `dumptorrent`
- `tudu`
- `JetBrainsMonoNL Nerd Font Mono`
- `JetBrainsMonoNL Nerd Font` — Waybar (`curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz | tar -xJ -C ~/.local/share/fonts --wildcards 'JetBrainsMonoNLNerdFont-*.ttf' && fc-cache -f ~/.local/share/fonts`)
- fonts-font-awesome
- `ShureTechMono Nerd Font Mono` — from Nerd Fonts `ShareTechMono.zip` into `~/.local/share/fonts`
- `clipse` (Wayland release tarball → `~/.local/bin/clipse`):
  `curl -fsSL https://github.com/savedra1/clipse/releases/download/v1.2.1/clipse_v1.2.1_linux_wayland_amd64.tar.gz | tar -xz -C /tmp && install -m 755 /tmp/clipse-linux-wayland-amd64 ~/.local/bin/clipse`
- `clipse-setup-uinput` (chezmoi-managed under `~/.local/bin`) after installing clipse:
  `clipse-setup-uinput` then re-login; verify with `clipse-setup-uinput --check`

## Minimal non-desktop/server install

For a terminal-only setup without Sway/Waybar desktop pieces:

```sh
# Fedora
sudo dnf install \
  aerc bat binutils chezmoi curl direnv eza fd-find fzf git git-delta gnupg2 isync \
  jq kitty less man-db neovim notmuch pandoc pass p7zip p7zip-plugins \
  poppler-utils ripgrep starship tmux vifm wl-clipboard xdg-utils zathura \
  khal khard vdirsyncer \
  zip zoxide go

# Ubuntu
sudo apt update
sudo apt install \
  aerc bat binutils curl direnv eza fd-find fzf git git-delta gnupg isync jq kitty \
  less man-db neovim notmuch p7zip-full pandoc pass poppler-utils ripgrep \
  starship tmux vifm wl-clipboard xdg-utils zathura khal khard vdirsyncer \
  zip zoxide go
```
