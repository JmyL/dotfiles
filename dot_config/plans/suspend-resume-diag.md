<!-- suspend-resume-diag -->
---
todos:
  - id: auto-dump
    content: Install ~/.local/bin/suspend-diag + /etc/systemd/system-sleep/zz-suspend-diag
    status: completed
  - id: next-incident
    content: On next black screen after resume, fill checklist below and inspect latest dump dirs
    status: pending
isProject: false
---

# Suspend/resume black-screen diagnostics

Automatic dumps for the next HDMI/NVIDIA/Sway resume black screen. No SSH required.

## What is installed

- `~/.local/bin/suspend-diag` — dump collector
- `/etc/systemd/system-sleep/zz-suspend-diag` — runs on every suspend `pre`/`post`
- Output: `~/.local/share/suspend-diag/<stamp>-{pre,post,user}/` (keeps last 20)

On resume (`post`), a delayed **user** dump also tries `swaymsg -t get_outputs`.

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
sudo tee /etc/systemd/system-sleep/zz-suspend-diag >/dev/null <<'EOF'
#!/bin/sh
# Thin wrapper; logic lives in the chezmoi-managed script.
exec /home/sungsik/.local/bin/suspend-diag system-sleep "$@"
EOF
sudo chmod 755 /etc/systemd/system-sleep/zz-suspend-diag
```
