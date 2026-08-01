<!-- suspend-resume-blackscreen-analysis -->
---
todos:
  - id: capture-context
    content: Fill incident checklist (wake/HDMI/lid/symptom) right after the event
    status: pending
  - id: locate-dumps
    content: Find matching pre/post/user stamps under ~/.local/share/suspend-diag
    status: pending
  - id: classify-failure
    content: Classify into DRM / kanshi-sway / NVIDIA / hybrid-race using the decision tree
    status: pending
  - id: compare-baseline
    content: Diff against a known-good resume dump (or 2026-08-01 journal facts below)
    status: pending
  - id: decide-fix
    content: Pick the smallest next experiment or fix; do not shotgun-change NVIDIA+kanshi together
    status: pending
isProject: false
---

# Suspend → blank screen: analysis runbook

Use this **after** the next resume black screen (forced reboot OK). Data collection is already wired; see [`suspend-resume-diag.md`](./suspend-resume-diag.md).

Goal: classify the failure class before changing config.

## 0. Incident checklist (human context)

Fill immediately (memory fades fast):

| Field | Value |
|-------|--------|
| Approx wake time | |
| Wake method | keyboard / lid / power / other |
| HDMI at wake | connected / disconnected / unknown |
| Lid at wake | open / closed |
| Symptom | full black / backlight only / cursor only / frozen frame |
| Ctrl+Alt+F3 | works / blank / not tried |
| Forced power off | yes / no |
| Notes before suspend | |

## 1. Locate dumps

```bash
ls -lt ~/.local/share/suspend-diag | head -20
```

Expect a matched stamp triad around wake time:

- `<stamp>-pre` — just before sleep
- `<stamp>-post` — root dump at resume (DRM/dmesg/journal)
- `<stamp>-user` — ~3s later (swaymsg outputs)

If `post` exists but `user` is missing → session/user bus likely dead or dump raced a hard power-off. Still analyze `post`.

If **no** new `pre`/`post` at all → sleep hook broken; reinstall steps in `suspend-resume-diag.md`.

Also pull journal for the previous boot if dumps are thin:

```bash
journalctl -b -1 --since 'TIME-5min' --until 'TIME+2min' --no-pager \
  -g 'suspend|resume|PM:|nvidia|Atomic|CRTC|kanshi|backend configuration|Page-flip|Failed to disable'
```

## 2. Fast pass (5 minutes)

Open these in order; note yes/no for each question.

### A. Did the machine actually resume?

`*-post/meta.txt`, `journal-pm.txt`, `dmesg-recent.txt`

- [ ] `PM: suspend exit` / `Operation 'suspend' finished` present
- [ ] `nvidia-resume.service` finished successfully

If **no** → different bug (stuck in sleep / failed resume). Stop; this runbook is for “alive but blank”.

### B. What did DRM think after resume?

Compare `*-pre/drm.txt` vs `*-post/drm.txt`:

| Connector | pre status/enabled | post status/enabled |
|-----------|--------------------|---------------------|
| eDP-1 | | |
| HDMI-A-1 | | |
| DP-* | | |

Questions:

- [ ] HDMI still `connected` after resume?
- [ ] Any connector `enabled` after resume?
- [ ] eDP enabled while HDMI also fighting (unexpected with `docked-hdmi`)?

### C. Did Sway/kanshi apply a profile?

`*-post/journal-pm.txt` and `*-user/journal-kanshi.txt` / `sway-outputs.txt`:

- [ ] kanshi chose `docked-hdmi` / `laptop` / other: ________
- [ ] `failed to apply configuration for profile '…'`
- [ ] `Atomic commit failed` / `Failed to disable CRTC` / `Page-flip failed`
- [ ] `Requested backend configuration failed` / `Search for valid config failed`
- [ ] `*-user/sway-outputs.txt` has at least one output with `"active": true` (or usable mode)

### D. NVIDIA-specific noise

`*-post/nvidia-smi.txt`, dmesg/journal:

- [ ] `nvidia-modeset: … Correcting number of heads … (0x00)`
- [ ] GPU visible in `nvidia-smi` after resume
- [ ] Repeated `Enabling HDA controller` storms (context only)

## 3. Decision tree (pick one primary class)

```
resume OK?
  no  → class: sleep/resume stuck (not this doc)
  yes → any connector enabled in post drm.txt?
          no  → class: DRM/modeset dead after resume
          yes → kanshi/sway apply failed OR Atomic/CRTC errors?
                  yes → class: compositor/kanshi config fail on half-alive DRM
                  no  → sway-outputs empty/inactive but drm enabled?
                          yes → class: Sway session/output state desync
                          no  → class: panel/backlight/DPMS only (rarer)
```

Map class → next move (still analysis / smallest experiment, not a fix dump):

| Class | Likely locus | Next experiment (one at a time) |
|-------|--------------|----------------------------------|
| DRM/modeset dead | NVIDIA + i915/xe hybrid after s2idle | Reproduce with HDMI unplugged (laptop-only). If laptop-only OK → external/NVIDIA path. |
| compositor/kanshi fail | kanshi race / bad mode after resume | Check whether failure is `docked-hdmi` then fallback `laptop` (2026-08-01 pattern). Try delaying kanshi or disabling external on lid-wake. |
| Sway desync | wlroots output state | Compare `sway-outputs` vs `drm.txt`; note if IPC dead. |
| backlight/DPMS | panel power | drm `dpms` On/Off vs symptom “backlight only”. |

## 4. Baseline: 2026-08-01 incident (known bad)

Use as comparison target, not as proof of sameness.

| Item | Fact |
|------|------|
| Suspend | 21:22 `s2idle`; nvidia-suspend OK |
| Resume | 22:27:01 kernel + nvidia-resume OK |
| Immediate | kanshi `docked-hdmi` (HDMI-A-1 + eDP-1) → **apply failed** |
| +25s | HDMI `Atomic commit failed: Invalid argument`; `Failed to disable CRTC 150` |
| Then | kanshi `laptop` → **also failed** |
| End | logs until 22:27:35; forced reboot ~22:28 |
| Earlier same day | 20:28 resume: same `docked-hdmi` **succeeded** |

Signature strings to grep in new dumps:

```bash
STAMP=<stamp>
rg -n 'Atomic commit failed|Failed to disable CRTC|backend configuration failed|failed to apply configuration|Page-flip failed|Correcting number of heads' \
  ~/.local/share/suspend-diag/${STAMP}-post ~/.local/share/suspend-diag/${STAMP}-user
```

## 5. Diff recipe (good vs bad)

When you have a **good** resume dump (smoke test after a normal wake) and a **bad** one:

```bash
GOOD=<good-stamp>
BAD=<bad-stamp>
diff -u ~/.local/share/suspend-diag/${GOOD}-post/drm.txt \
        ~/.local/share/suspend-diag/${BAD}-post/drm.txt
diff -u ~/.local/share/suspend-diag/${GOOD}-user/sway-outputs.txt \
        ~/.local/share/suspend-diag/${BAD}-user/sway-outputs.txt | head -100
```

Also compare human checklist: HDMI/lid/wake method must match or the diff is apples/oranges.

## 6. Analysis notes (fill after classifying)

- Primary class:
- Evidence files (paths):
- Same as 2026-08-01?: yes / no / partial — why:
- Smallest next step (one change or one repro only):
- Explicitly **not** doing yet:

## 7. Out of scope until classified

Do not mix these until the class is chosen:

- NVIDIA driver bump / `nvidia-drm.modeset` cmdline churn
- kanshi profile rewrite
- switching sleep from `s2idle` to deep
- enabling SSH “just in case”

One variable per experiment.
