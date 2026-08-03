<!-- suspend-resume-diag -->
---
todos:
  - id: auto-dump
    content: Install ~/.local/bin/suspend-diag + /usr/lib/systemd/system-sleep/zz-suspend-diag
    status: pending
  - id: next-incident
    content: On next black screen after resume, follow suspend-resume-blackscreen-analysis.md
    status: pending
isProject: false
---

# Suspend/resume black-screen diagnostics

Automatic dumps for the next HDMI/NVIDIA/Sway resume black screen. No SSH required.

**When it fails again:** use the analysis runbook
[`suspend-resume-blackscreen-analysis.md`](./suspend-resume-blackscreen-analysis.md)
(checklist → dumps → decision tree → next experiment). This file is only the collector setup.

## What is installed

- `~/.local/bin/suspend-diag` — dump collector (`#!/usr/bin/bash` + explicit `PATH`; sleep hooks often have empty PATH so `env bash` used to fail silently)
- `/usr/lib/systemd/system-sleep/zz-suspend-diag` — sets `PATH`, `logger -t suspend-diag`, then runs the script
- Output: `~/.local/share/suspend-diag/<stamp>-{pre,post,user0,user}/` (keeps last 20)

**Path note (Ubuntu 26.04 / systemd 259):** `systemd-sleep` only executes hooks under
`/usr/lib/systemd/system-sleep/`. A wrapper under `/etc/systemd/system-sleep/` is **ignored**
(confirmed 2026-08-03: no `suspend-diag` journal on real suspend). Do not reinstall to `/etc`.

On resume (`post`):

1. root dump (`drm`/`dmesg`/journal) + `sync`
2. immediate `user0` swaymsg snapshot
3. ~3s later `user` snapshot (+ fuller user dump if session still alive)

Hook progress markers: `hook-started.txt` / `hook-finished.txt`. Journal tag: `suspend-diag`.

### Verify after next suspend (even if screen is fine)

```bash
journalctl -t suspend-diag --since '10 min ago' --no-pager
ls -lt ~/.local/share/suspend-diag | head
```

Expect `hook invoked`, `system-sleep pre/post`, and matching `*-pre` / `*-post` dirs.
Mark `auto-dump` completed only after a real suspend produces `*-post`.

## When it happens again — fill this in

Copy into a daily note or leave filled here:

- Date/time (approx wake):
- Wake method: keyboard / lid open / power button / other:
- External HDMI at wake: connected / disconnected / unknown
- Lid at wake: open / closed
- Screen symptom: full black / backlight only / cursor only / frozen old frame
- Ctrl+Alt+F3 TTY: works / blank / not tried
- Forced power off?: yes / no
- Anything unusual before suspend (dock unplug, monitor sleep, GPU switch):

## After reboot (or if session recovers) — look here

```bash
ls -lt ~/.local/share/suspend-diag | head
# pick matching pre/post/user stamps around the incident
less ~/.local/share/suspend-diag/<stamp>-post/drm.txt
less ~/.local/share/suspend-diag/<stamp>-post/dmesg-recent.txt
less ~/.local/share/suspend-diag/<stamp>-post/journal-pm.txt
less ~/.local/share/suspend-diag/<stamp>-user/sway-outputs.txt
```

Useful contrasts:

- `pre` vs `post` `drm.txt` — which connectors survived resume
- `post` journal Atomic/CRTC/kanshi lines — same class as 2026-08-01 incident
- `user/sway-outputs.txt` — whether Sway still had a usable output config

## Manual test (safe)

```bash
suspend-diag user-resume
ls -lt ~/.local/share/suspend-diag | head
```

To exercise the sleep hook end-to-end, suspend once briefly and check for new `*-pre` / `*-post` / `*-user` dirs.

## Reinstall system hook (if missing after OS reset)

```bash
sudo tee /usr/lib/systemd/system-sleep/zz-suspend-diag >/dev/null <<'EOF'
#!/bin/sh
# systemd-sleep often has an empty PATH; keep this wrapper dumb and logged.
# Ubuntu 26.04 / systemd 259 only runs hooks from /usr/lib/systemd/system-sleep
# (not /etc/systemd/system-sleep).
export PATH="/usr/sbin:/usr/bin:/sbin:/bin"
logger -t suspend-diag "hook invoked args=$*"
exec /home/sungsik/.local/bin/suspend-diag system-sleep "$@"
EOF
sudo chmod 755 /usr/lib/systemd/system-sleep/zz-suspend-diag
sudo rm -f /etc/systemd/system-sleep/zz-suspend-diag
```
