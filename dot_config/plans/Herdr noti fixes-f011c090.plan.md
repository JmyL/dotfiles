<!-- f011c090-76a0-4ce4-80f8-7804b64bb2ed -->
---
todos:
  - id: herdr-toast-on
    content: "Set ui.toast.delivery=herdr; keep ui.sound; chezmoi add/commit/push; reload"
    status: pending
  - id: clone-plugin
    content: "Clone JmyL/herdr-focus-notify to ~/projects/herdr-focus-notify and branch from current SHA"
    status: pending
  - id: fix-default-action
    content: "Add notify-send default+focus actions and case match; tests"
    status: pending
  - id: enrich-body
    content: "Enrich notification body from agent list (basename(cwd) · terminal_title)"
    status: pending
  - id: ship-plugin
    content: "Push plugin as JmyL, bump plugins.list, reinstall, chezmoi add/commit/push"
    status: pending
  - id: sound-decision
    content: "Sound policy deferred — decide after Chrome/Slack vs swaync behavior is settled"
    status: pending
isProject: false
---
# Herdr toast + focus-notify fixes

## Toast: dual visual is OK

Accepted split:

| When | What you see |
|---|---|
| Looking at that agent pane/tab | Plugin skips desktop noti; Herdr also suppresses active-tab toast → quiet |
| Looking at another Herdr workspace/tab | In-app Herdr toast (visible) + maybe plugin desktop |
| Herdr not focused / other app | Plugin swaync desktop (visible); Herdr toast unseen |

So set:

```toml
[ui.toast]
delivery = "herdr"
```

Keep Herdr `[ui.sound]` as-is for now (default on). Plugin remains the clickable desktop path.

## Why config reload still toasts with `delivery = "off"`

`ui.toast.delivery` gates **agent / `notification.show` background popups**, not every in-app banner.

Config reload sets the in-app toast **directly** in Herdr’s UI code (`title: "reloaded config"`, `context: "using config.toml"`) and does **not** check `delivery`. Clipboard “copied to clipboard” feedback is similarly separate (`ui.toast.clipboard`).

So reload feedback with `delivery = "off"` is expected, not a misconfiguration.

## Sound: deferred (Chrome analogy)

Slack/Chrome often play sound **inside the app**, while swaync only shows the banner. Herdr already has the same pattern via `[ui.sound]`.

The double agent sound today is specifically:

1. Herdr `[ui.sound]` on agent state change
2. swaync global script on **every** receive, including plugin `notify-send`

Likely end state (Chrome-like): Herdr keeps its own sound; swaync should not also beep for plugin (or drop the global swaync sound script if most apps self-sound). **Do not change swaync/sound in this pass** until you decide. Options to pick later:

- Mute swaync only for `app-name=herdr-focus-notify` (plugin sets `-a`)
- Remove swaync `notification-sound` entirely (rely on app-owned sounds)
- Keep both (current double beep on agent done)

## Plugin work location

Clone `https://github.com/JmyL/herdr-focus-notify.git` → [`~/projects/herdr-focus-notify`](/home/sungsik/projects/herdr-focus-notify), branch from pinned SHA `9141cd0`. Develop / test with `herdr plugin link`; push as `JmyL`; bump [`plugins.list`](/home/sungsik/.config/herdr/plugins.list); reinstall; chezmoi commit/push.

Do not treat the managed detached checkout under `~/.config/herdr/plugins/github/...` as the primary edit tree.

## Plugin code changes (this pass)

1. **Focus click:** `-A default=Focus -A focus=Focus`; match `default` or `focus` (swaync body click uses `default`).
2. **Body (idea 1):** from `herdr agent list`, `basename(cwd) · terminal_title_stripped|terminal_title` (truncate; fall back to event title / generic).
3. Tests for script generation + body enrichment.

Optional prep for later sound mute: set `-a herdr-focus-notify` now so a future swaync filter is trivial. Include this small flag even while sound policy is deferred.

## Herdr config (this pass)

Edit live [`~/.config/herdr/config.toml`](/home/sungsik/.config/herdr/config.toml): `ui.toast.delivery = "herdr"`. chezmoi add/commit/push as `JmyL`; `herdr server reload-config`.

## Verify

- Config reload still shows in-app “reloaded config”.
- Agent done while elsewhere: Herdr toast + plugin desktop; body click focuses pane.
- Agent done while on that pane: no (or suppressed) duplicate nag.
- Body shows `project · title` when metadata exists.
- Sound: leave as-is until decision; note whether double beep still happens.
