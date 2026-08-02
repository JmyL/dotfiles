# Fedora upgrade aftercare for local swaync

## Summary

After a Fedora Silverblue version upgrade, do not blindly trust the patched/mainline `swaync` installed under `~/.local/bin`. Recheck it against the new host runtime and rebuild it from a matching Fedora userspace if needed.

## Key changes

- Treat a Fedora Silverblue upgrade as a rebuild checkpoint for `~/.local/bin/swaync` and `~/.local/bin/swaync-client`.
- Build from a toolbox/dev container whose Fedora version matches the host major version.
- Keep the sway config unchanged: local `~/.local/bin` first, packaged `/usr/bin` fallback.
- Do not use `dev-launcher` for the notification daemon or client keybindings.

## Rebuild procedure

1. Check the upgraded host:

   ```sh
   cat /etc/os-release
   rpm -q glibc gtk4 gtk4-layer-shell libadwaita SwayNotificationCenter
   ```

2. Check the existing local binaries:

   ```sh
   ldd ~/.local/bin/swaync
   ldd ~/.local/bin/swaync-client
   ~/.local/bin/swaync-client --help
   ```

3. If `ldd` reports `not found`, or if GLib/GTK/libadwaita symbol errors appear at runtime, rebuild from a matching Fedora userspace:

   ```sh
   meson setup build --prefix="$HOME/.local" --buildtype=release
   meson compile -C build
   meson install -C build
   ```

4. Reload sway and verify the local daemon is active:

   ```sh
   sway reload
   pgrep -a swaync
   notify-send "swaync test" "hello"
   ```

## Test plan

- `ldd ~/.local/bin/swaync` and `ldd ~/.local/bin/swaync-client` have no `not found` entries.
- `~/.local/bin/swaync-client --help` still shows the patched default-action behavior.
- `$mod+Return` activates the latest notification's default action.
- Removing `~/.local/bin/swaync*` and reloading sway falls back to packaged `/usr/bin/swaync`.

## Assumptions

- This plan is for later Fedora/Silverblue upgrades, not the initial patched swaync rollout.
- Host-level rpm-ostree changes are out of scope by default.
- `swaync.service` remains masked; sway continues to launch the daemon via `exec_always`.
