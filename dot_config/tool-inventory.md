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

Config: `~/.bashrc`, `~/.bashrc.d/browser`, `~/.bashrc.d/bash-completion`, `~/.bashrc.d/lnav`, `~/.bashrc.d/xauthority`

- `nvim` is exported as `VISUAL` and `EDITOR`.
- `lnav` defaults to `TZ=UTC`; `lnavl` uses the system timezone.
- `~/.bashrc.d/xauthority` creates `~/.Xauthority` when missing on local `:0` (Sway/Xwayland). Needs `xauth` and `mcookie`.
- `bash-completion` is required for `apt install <TAB>` package-name completion on Ubuntu (Fedora already loads it from `/etc/bashrc`).
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
- `darkman` — session dark/light preference via xdg-desktop-portal (`org.freedesktop.appearance color-scheme`). Kitty follows it with `light-theme.auto.conf` / `dark-theme.auto.conf`. Vivaldi chrome Dark (`Vivaldi2`) / Zen (`VivaldiZen`) is set by `vivaldi-darkman-host --apply-chrome` over localhost CDP; start Vivaldi via `~/.local/bin/vivaldi-stable` (`$mod+Shift+i`) so `--remote-debugging-port=19222` is on. Do not give the local extension the `debugger` permission — Vivaldi disables it. Dark Reader on/off is still the `vivaldi-darkman` extension (nativeMessaging + management only). GTK/`gsettings` follow via `~/.local/bin/vivaldi-darkman-theme`. Manual only (`darkman set light` / `darkman set dark` / `darkman toggle`); geoclue/sun times are off. User systemd unit `darkman.service`.
- `foot` — fast floating terminal for `fzf-menu` / `fzf-drun` / `clipse` (font matched to kitty). Ubuntu 26.04 apt is 1.25 (no `[colors-dark]`); build ≥1.26 to `~/.local` from https://codeberg.org/dnkl/foot/releases
- `fzf` — used by floating `fzf-menu` / `fzf-drun` pickers (replaces fuzzel)
- `swayidle`
- `swayosd`
- `swaylock`
- `thunar`
- `flatpak`
- Brave Browser as Flatpak app `com.brave.Browser`, or equivalent browser setup (still used for packing local extensions / optional browsing)
- Vivaldi (`vivaldi-stable`) — Sway `$mod+Shift+i` default browser on this setup
- Firefox (`firefox`, snap `firefox` on Ubuntu) — required for `reeplay.reeinfra.net` playback (HEVC HLS). `xdg-open` and the Reeplay-open-in-Firefox extension launch it; Sway `app_id` is `firefox_firefox` for the snap.
- 1Password desktop (`1password`) + CLI (`op`) — `ree-goodmorning` / `vay-token-update` TOTP. Linux Vivaldi needs `/etc/1password/custom_allowed_browsers` to contain `vivaldi-bin` (uncomment; restart 1Password) so the extension shares the app lock
- Twingate CLI (`twingate`) — `ree-goodmorning` / Waybar VPN status (`Berlin_Testbeds_ALL`)
- AWS CLI (`aws`) + `~/projects/vay-aws-mfa` — `vay-token-update` writes `~/.aws/vay_aws_mfa_cache.env`
- Vivaldi UI pack: `~/.config/vivaldi-ui/` (chezmoi) — `layout.json` only (toolbar composition, hidden extension toolbar icons, tab/address bar bottom, native window, hidden side panel bar, no auto Downloads panel). No custom CSS. Apply with `vivaldi-setup-ui` while Vivaldi is quit (clears Custom UI Modifications + merges `layout.json` into Preferences; refuses to run while Vivaldi is open). Do **not** track `~/.config/vivaldi/` profile state.
- Tampermonkey (Brave/Chrome/Vivaldi extension) — runs userscripts under `~/.config/userscripts/` (e.g. `circleci-tab-status.user.js`). Install/update by opening the `.user.js` file in the browser or pasting into Tampermonkey → Create a new script.
- Local Chromium extension `~/.local/share/brave-extensions/slack-stay-in-browser` — rewrites Slack `archives` permalinks to `messages` so they open in the web client without the desktop-app prompt; Alt+S focuses an open Slack tab (`vivaldi://extensions/shortcuts` / `brave://extensions/shortcuts`). Pack/register with `brave-install-local-extensions` (writes `.crx`/`.pem` under `~/.local/state/brave-extensions/` and External Extensions JSON for both Brave and Vivaldi). Restart the browser fully after installing or upgrading on a new machine.
- Local Chromium extension `~/.local/share/brave-extensions/reeplay-open-firefox` — intercepts `reeplay.reeinfra.net` navigations and hands them to `~/.local/bin/reeplay-open-firefox` (native messaging host `com.sungsik.reeplay_open_firefox`). Same installer writes the host manifest under Vivaldi/Brave `NativeMessagingHosts/`. `~/.local/bin/xdg-open` also sends that host to Firefox so terminal/Slack/Herdr links match. Restart the browser fully after installing.
- Local Chromium extension `~/.local/share/brave-extensions/vivaldi-darkman` — native host `~/.local/bin/vivaldi-darkman-host` (`com.sungsik.vivaldi_darkman`) enables Dark Reader when darkman is dark and disables it when light. Vivaldi chrome Dark/Zen is applied by the same host over localhost CDP, not `chrome.debugger` (that permission made Vivaldi disable the extension). Start Vivaldi with `~/.local/bin/vivaldi-stable`. Restart the browser fully after installing or upgrading.

Vivaldi UI checklist (new machine):

1. Install `vivaldi-stable` and Firefox, then once: `brave-install-local-extensions` and fully restart Vivaldi (Slack stay-in-browser + Reeplay open in Firefox + darkman Dark Reader).
2. Quit Vivaldi, run `vivaldi-setup-ui`, start Vivaldi — toolbar/hidden icons + bar positions from `vivaldi-ui/layout.json`. Custom CSS is left off.
3. After changing toolbars, “Hide button” on an extension icon, or Downloads settings in the UI, copy the new `toolbars.*` / `address_bar.extensions.hidden_extensions` / `downloads.*` values into `~/.config/vivaldi-ui/layout.json`, then `chezmoi add` that file. `downloads.open_panel_on_new=false` keeps the left Downloads panel from opening on each download.
4. Themes: OS schedule Dark (`Vivaldi2`) / Zen (`VivaldiZen`) via `layout.json` `theme.schedule.o_s` so Super+Shift+t / darkman switches the chrome. Coloring mode **not Unified** (`layout.json` sets `theme_color_position=addressbar` on the scheduled theme). Stock theme edits can reset on update.
5. Side panel: hidden (`layout.json` `panels.window_defaults.barVisible=false`). F4 still toggles it. Unified + Auto-Hide can leave a frame; leave Auto-Hide off.
6. Confirm `vivaldi://extensions` has Slack stay-in-browser, Reeplay open in Firefox, and darkman Dark Reader; shortcuts: Alt+S for Slack tab focus. Hidden toolbar icons (Show Tab Numbers, Slack stay-in-browser, Reeplay open in Firefox, darkman Dark Reader) still run in the background.

Audio:

- `wireplumber` (`wpctl`) and `pipewire-bin`/`pipewire-utils` (`pw-dump`) — used by `sway-audio-switch` to list/switch default audio devices

Screenshot/recording/clipboard:

- `grim`
- `grimshot` / sway screenshot helper
- `slurp`
- `swappy`
- `wl-clipboard` (`wl-copy`, `wl-paste`)
- `clipse` — clipboard history TUI (`$mod+v`); install Wayland amd64 release to `~/.local/bin/clipse`. **autoPaste** on Wayland needs `/dev/uinput` access: run `~/.local/bin/clipse-setup-uinput` on each machine (idempotent; uses sudo). Check with `clipse-setup-uinput --check`. On Fedora Silverblue/toolbox, run it on the **host**. Then **log out and back in** so group `input` is active in the session.
- `wf-recorder`
- `seekey` — Wayland keystroke OSD bubbles (`~/.local/bin/seekey`). Not packaged in apt/dnf; build [Seekey](https://github.com/Nakanomk/Seekey) (`v0.2.3`) with `./install.sh --user --no-input`. Needs `input` group read access to `/dev/input/event*` (same as `clipse-setup-uinput`). Desktop entry `~/.local/share/applications/dev.seekey.desktop` must use the absolute `~/.local/bin/seekey` path (Sway PATH has no `~/.local/bin`). Launcher opens the Seekey menu (`--xdg --desktop-launch`). Not autostarted.
- `showmethekey` — GTK keystroke overlay (`showmethekey-gtk`). Not packaged in apt; Fedora COPR `pesader/showmethekey`, otherwise build [v1.21.0](https://github.com/AlynxZhou/showmethekey) to `/usr/local`. In the `input` group it runs `showmethekey-cli` without pkexec. Sway window rules live in `~/.config/sway/config.d/20-showmethekey.conf`. Not autostarted.
- `librnnoise_ladspa.so` — user-local LADSPA plugin for screen-recording mic denoise (`~/.local/lib/ladspa/librnnoise_ladspa.so`). Not packaged in apt/dnf. From the [noise-suppression-for-voice](https://github.com/werman/noise-suppression-for-voice/releases) `linux-rnnoise.zip` (`linux-rnnoise/ladspa/librnnoise_ladspa.so`). Do not install it as a session-wide PipeWire source; `sway-recording` loads it only while recording.
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
- `fcitx5-vi-escape` — Esc / Ctrl-[ deactivates Hangul and still forwards the key; not in distro repos, build from https://github.com/anyakichi/fcitx5-vi-escape. Requires `DeactivateKeys` not to include Escape.

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
- `bun` (needed by some Herdr plugins, e.g. `rjyo/herdr-window-title-sync`)
- `uv`, `uvx`
- `gh`
- `gh` extension `dlvhdr/gh-dash` (`gh extension install dlvhdr/gh-dash`)
- `gh-review` — line-level PR review TUI used from gh-dash (`R`); `cargo install gh-review`
- `act`
- `k6`
- `zellij`
- `tuxedo`
- `pop-launcher`
- `playwright-cli` (`@playwright/cli`) — coding-agent browser automation (CLI + skill, not Playwright MCP). User-global: `npm install -g @playwright/cli@latest --prefix ~/.npm-global`. Then `playwright-cli install-browser` and `playwright-cli install --skills=claude --global`. Cursor also needs `ln -sfn ../../.claude/skills/playwright-cli ~/.cursor/skills/playwright-cli`. Default browser is bundled Chromium via `~/.playwright/cli.config.json` (no Google Chrome at `/opt/google/chrome`; Ubuntu AppArmor needs `chromiumSandbox: false`).

## Fedora install command

This is the broad workstation-oriented install set. Some packages may vary by Fedora release or repositories.
On Fedora Silverblue, run this broad `dnf install` inside the toolbox/dev
container for CLI and build tools. Do not treat it as a host setup command.
Host-session tools that Sway starts directly (`sway`, `waybar`, `vivaldi-stable`,
`1password`, `twingate`, `swaync-client`, `swayosd-client`, `showmethekey`,
input-device helpers) must be installed on the host via Flatpak, rpm-ostree, or
user-local upstream installers as noted below.

```sh
sudo dnf install \
  aerc atuin bat binutils blueman catdoc chezmoi curl direnv dnf-plugins-core \
  docx2txt eza fcitx5 fcitx5-hangul fd-find ffmpeg-free flatpak foot fzf git git-delta gnupg2 grim \
  grimshot isync jq kanshi kitty less libcanberra-gtk3 libnotify links lynx man-db \
  mp3info neovim notmuch pandoc pass p7zip p7zip-plugins poppler-utils python3-gobject \
  power-profiles-daemon ripgrep slurp sox starship swappy sway swayidle \
  khal khard vdirsyncer \
  swaylock thunar tmux transmission unrar vifm vimiv vlc waybar wf-recorder \
  wl-clipboard wtype xorg-x11-xauth xclip xdg-utils xterm zathura zip zoxide wireplumber pipewire-utils
```

Fedora follow-ups:

```sh
# tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Brave browser, if using the Flatpak app expected by sway config
flatpak install flathub com.brave.Browser
```

Fedora Silverblue host notes:

- `atuin`: install it wherever interactive shells run. For toolbox shells,
  `sudo dnf install atuin` inside the toolbox is enough; for host shells, prefer
  Atuin's user install under `~/.atuin/bin` or layer the Fedora package with
  `rpm-ostree install atuin`.
- `vivaldi-stable`: Sway `$mod+Shift+i` starts `$HOME/.local/bin/vivaldi-stable`,
  which execs `/usr/bin/vivaldi-stable` with a localhost CDP port for darkman
  Dark/Zen. On Silverblue the real binary must still be a host install, not only
  a toolbox package. Install the Vivaldi RPM/repository on the host with
  rpm-ostree, or change the Sway binding before using a Flatpak/browser
  alternative.
- `firefox`: host browser for `reeplay.reeinfra.net` (HEVC). Flatpak
  `org.mozilla.firefox` or an rpm-ostree Firefox is fine; set `FIREFOX` /
  `FIREFOX_APP_ID` if the binary or Sway `app_id` is not `firefox` /
  `firefox_firefox`.
- `1password` browser integration needs the host file
  `/etc/1password/custom_allowed_browsers` to include `vivaldi-bin`; make that
  change on the host, then restart 1Password.
- `seekey`, `showmethekey`, `clipse-setup-uinput`, and `fcitx5-vi-escape` touch
  host input devices or host input-method paths. Build/install them from a
  matching toolbox if useful, but run the final install/setup step against the
  host and log out/in after group or udev changes.
- `darkman` must run in the host user session (D-Bus / xdg-desktop-portal). On
  Silverblue, `rpm-ostree install darkman` on the host, or the same `~/.local/bin`
  build as Ubuntu. Do not rely on a toolbox-only binary.
- `herdr-install-plugins` can run from the toolbox because Herdr plugin files
  live under the shared home directory. Herdr plugin actions that call `swaymsg`
  use `flatpak-spawn --host` fallback when they are invoked from a toolbox.

May need separate installation depending on Fedora version/repositories:

- `darkman` — host user session (`sudo dnf install darkman`; Silverblue `rpm-ostree install darkman`, or the Ubuntu `~/.local/bin` build). Not a toolbox-only install.
- `swayosd-client`
- `swaync-client`
- `sesh`
- `tmuxinator`
- `pi`
- `herdr`
- `1password` + `op` (1Password Linux + CLI)
- `twingate`
- `awscli`
- `bun` — `curl -fsSL https://bun.sh/install | bash` (symlink `~/.bun/bin/bun` into `~/.local/bin` if Herdr's PATH lacks `~/.bun/bin`)
- `uv`
- `gh` extension `dlvhdr/gh-dash`: `gh extension install dlvhdr/gh-dash`
- `gh-review`: `cargo install gh-review`
- `playwright-cli`: `npm install -g @playwright/cli@latest --prefix ~/.npm-global && playwright-cli install-browser && playwright-cli install --skills=claude --global && ln -sfn ../../.claude/skills/playwright-cli ~/.cursor/skills/playwright-cli`
- `JetBrainsMonoNL Nerd Font Mono`
- `JetBrainsMonoNL Nerd Font` — Waybar (`curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz | tar -xJ -C ~/.local/share/fonts --wildcards 'JetBrainsMonoNLNerdFont-*.ttf' && fc-cache -f ~/.local/share/fonts`)
- `clipse` (Wayland release tarball → `~/.local/bin/clipse`):
  `curl -fsSL https://github.com/savedra1/clipse/releases/download/v1.2.1/clipse_v1.2.1_linux_wayland_amd64.tar.gz | tar -xz -C /tmp && install -m 755 /tmp/clipse-linux-wayland-amd64 ~/.local/bin/clipse`
- `clipse-setup-uinput` (chezmoi-managed under `~/.local/bin`) after installing clipse:
  `clipse-setup-uinput` then re-login; verify with `clipse-setup-uinput --check`
- `seekey` (`v0.2.3` → `~/.local/bin/seekey`):
  `sudo dnf install gtk4-devel libevdev-devel ncurses-devel json-glib-devel gtk4-layer-shell-devel gettext pkgconf-pkg-config gcc make && git clone --depth 1 --branch v0.2.3 https://github.com/Nakanomk/Seekey.git /tmp/Seekey && /tmp/Seekey/install.sh --user --no-input`
- `fcitx5-vi-escape` (source → `/usr`):
  `sudo dnf install cmake extra-cmake-modules gcc-c++ fcitx5-devel && git clone https://github.com/anyakichi/fcitx5-vi-escape.git /tmp/fcitx5-vi-escape && cmake -S /tmp/fcitx5-vi-escape -B /tmp/fcitx5-vi-escape/build -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release && cmake --build /tmp/fcitx5-vi-escape/build && sudo cmake --install /tmp/fcitx5-vi-escape/build`
- `showmethekey`:
  `sudo dnf copr enable pesader/showmethekey && sudo dnf install showmethekey`
- `librnnoise_ladspa.so` — `mkdir -p ~/.local/lib/ladspa && curl -fsSL https://github.com/werman/noise-suppression-for-voice/releases/download/v1.10/linux-rnnoise.zip -o /tmp/linux-rnnoise.zip && unzip -jo /tmp/linux-rnnoise.zip 'linux-rnnoise/ladspa/librnnoise_ladspa.so' -d ~/.local/lib/ladspa`

## Ubuntu install command

Test/package names may vary by Ubuntu release. This is aimed at recent Ubuntu versions.

```sh
sudo apt update
sudo apt install \
  aerc atuin bash-completion bat binutils blueman catdoc curl direnv docx2txt eza fcitx5 fcitx5-hangul \
  fd-find ffmpeg flatpak foot fzf git git-delta gnupg grim isync jq kanshi kitty less \
  libcanberra-gtk3-bin libnotify-bin links lynx man-db mp3info neovim notmuch p7zip-full \
  p7zip-rar pandoc pass poppler-utils power-profiles-daemon ripgrep \
  khal khard vdirsyncer \
  slurp sox starship swappy sway swayidle swaylock swayosd thunar tmux \
  transmission-cli unrar vifm vimiv vlc waybar wf-recorder wl-clipboard \
  wtype xauth xclip xdg-utils xterm zathura zip zoxide grimshot build-essential libreadline-dev unzip \
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

- `darkman` (not in Ubuntu apt): `sudo apt install golang-go scdoc` then `git clone --depth 1 --branch v2.3.1 https://gitlab.com/WhyNotHugo/darkman.git /tmp/darkman && make -C /tmp/darkman && install -Dm755 /tmp/darkman/darkman ~/.local/bin/darkman && systemctl --user daemon-reload && systemctl --user enable --now darkman.service`
- `foot` ≥1.26 (Ubuntu 26.04 apt is 1.25): build to `~/.local` — `sudo apt install meson ninja-build libwayland-dev wayland-protocols libxkbcommon-dev libfontconfig-dev libfreetype-dev libpixman-1-dev libfcft-dev libtllist-dev libutf8proc-dev libutempter-dev scdoc` then from the [release tarball](https://codeberg.org/dnkl/foot/releases): `meson setup build --buildtype=release --prefix="$HOME/.local" && ninja -C build install`
- npm install -g @mermaid-js/mermaid-cli
- brave-browser (still used to pack local `.crx` via `brave-install-local-extensions`)
- vivaldi-stable (Sway `$mod+Shift+i`; install from Vivaldi’s apt repo or package)
- `firefox` (snap `firefox` on Ubuntu; HEVC playback for `reeplay.reeinfra.net`)
- `grimshot` may come from `sway-contrib` or need a manual install depending on release.
- `swayosd-client`
- `swaync-client`
- `sesh`: go install github.com/joshmedeski/sesh/v2@latest
- `tmuxinator`
- `pi`
- `herdr`
- `1password` + `op` (1Password Linux + CLI)
- `twingate`
- `awscli`
- `bun` — `curl -fsSL https://bun.sh/install | bash` (symlink `~/.bun/bin/bun` into `~/.local/bin` if Herdr's PATH lacks `~/.bun/bin`)
- `uv`
- `gh` extension `dlvhdr/gh-dash`: `gh extension install dlvhdr/gh-dash`
- `gh-review`: `cargo install gh-review`
- `playwright-cli`: `npm install -g @playwright/cli@latest --prefix ~/.npm-global && playwright-cli install-browser && playwright-cli install --skills=claude --global && ln -sfn ../../.claude/skills/playwright-cli ~/.cursor/skills/playwright-cli`
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
- `seekey` (`v0.2.3` → `~/.local/bin/seekey`):
  `sudo apt install libgtk-4-dev libevdev-dev libncurses-dev libjson-glib-dev libgtk4-layer-shell-dev gettext pkg-config build-essential && git clone --depth 1 --branch v0.2.3 https://github.com/Nakanomk/Seekey.git /tmp/Seekey && /tmp/Seekey/install.sh --user --no-input`
- `fcitx5-vi-escape` (source → `/usr`):
  `sudo apt install cmake extra-cmake-modules g++ pkg-config libfcitx5core-dev libfcitx5config-dev libfcitx5utils-dev fcitx5-modules-dev && git clone https://github.com/anyakichi/fcitx5-vi-escape.git /tmp/fcitx5-vi-escape && cmake -S /tmp/fcitx5-vi-escape -B /tmp/fcitx5-vi-escape/build -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release && cmake --build /tmp/fcitx5-vi-escape/build && sudo cmake --install /tmp/fcitx5-vi-escape/build`
- `showmethekey` (`v1.21.0` → `/usr/local/bin/showmethekey-gtk`):
  `sudo apt install meson ninja-build libgtk-4-dev libadwaita-1-dev libevdev-dev libinput-dev libjson-glib-dev libxkbcommon-dev libxkbregistry-dev && git clone --depth 1 --branch v1.21.0 https://github.com/AlynxZhou/showmethekey.git /tmp/showmethekey && meson setup --prefix=/usr/local --buildtype=release /tmp/showmethekey/build && meson compile -C /tmp/showmethekey/build && sudo meson install -C /tmp/showmethekey/build`
- `librnnoise_ladspa.so` — `mkdir -p ~/.local/lib/ladspa && curl -fsSL https://github.com/werman/noise-suppression-for-voice/releases/download/v1.10/linux-rnnoise.zip -o /tmp/linux-rnnoise.zip && unzip -jo /tmp/linux-rnnoise.zip 'linux-rnnoise/ladspa/librnnoise_ladspa.so' -d ~/.local/lib/ladspa`

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
  aerc bash-completion bat binutils curl direnv eza fd-find fzf git git-delta gnupg isync jq kitty \
  less man-db neovim notmuch p7zip-full pandoc pass poppler-utils ripgrep \
  starship tmux vifm wl-clipboard xdg-utils zathura khal khard vdirsyncer \
  zip zoxide go
```
