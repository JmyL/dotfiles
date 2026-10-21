---
name: pi-herdr-noti-pipeline
description: Use when working on pi/herdr notifications, alarms, agent-state reporting, input-request alerts, or anything touching tmux-agent-notify, herdr-agent-state, herdr-focus-notify, ai-notify-and-goto, or the "herdr:blocked" event — 알람/알림(noti/notify/alarm) 관련 pi·herdr 작업 시 파이프라인 구조와 함정을 먼저 확인한다.
---

# pi × herdr notification pipeline

How the user's agent alarms actually work, and the traps that have caused wrong
fixes before. Verified end-to-end on 2026-10-22 (goal mviqg3ih-ztdq77).

## Components and data flow

There are two pane worlds. Do not assume one fix covers both.

**herdr pane** (`HERDR_ENV=1`, `HERDR_PANE_ID` set — herdr-managed tab/pane):

```
pi extension "herdr:blocked" emit
  → ~/.pi/agent/extensions/herdr-agent-state.ts   (installed by `herdr integration install pi`; herdr OWNS this file)
  → socket pane.report_agent {state: "blocked", message}
  → herdr server marks the pane blocked (screen_detection_skipped=true ⇒ report-driven, not TUI scanning)
  → herdr-focus-notify plugin → desktop notification (blocked, done only; suppressed while the pane is focused)
```

**Plain pane** (tmux/kitty/sway, no herdr env):

```
pi extension "herdr:blocked" emit
  → ~/.pi/agent/extensions/tmux-agent-notify.ts (personal, chezmoi) — listens to "herdr:blocked"
  → notifyBlocked(): @ai_state pane option + state file
     ($XDG_RUNTIME_DIR/ai-hook-notify/agents/tmux-<pane>.json, pane id chars are _-sanitized, e.g. tmux-_0.json)
  → spawn ai-notify-and-goto <agent> <target> <title> <body>  → desktop notification + sound
```

Turn-end alarms are separate and already exist in both worlds: `agent_end` →
tmux-agent-notify `notifyDone` (plain panes) / `agent_settled` → idle report
(herdr panes; herdr-focus-notify alarms only on blocked/done, NOT idle).

## The "herdr:blocked" event bus pattern

- `pi.events` is an official extension-to-extension bus (`emit`/`on`); see
  pi examples `extensions/event-bus.ts`. Nothing in pi core emits
  `herdr:blocked` — it is a private convention consumed by the two extensions
  above (herdr's *omp* integration detects its `ask` tool natively, but the
  *pi* integration does not detect any tool; it only listens to this event).
- Shape: `{ active: true, label: "<short question/summary>" }` to enter,
  `{ active: false }` to leave. `label` becomes the notification body/state
  message (herdr) and the notify body (plain panes).
- To alarm on a new input-request surface, publish this event from a custom
  extension; never edit herdr-agent-state.ts — `herdr integration install`
  (or update) silently overwrites it. Custom extensions go beside it in
  `~/.pi/agent/extensions/` (existing example: `goal-input-notify.ts`).

## pi-goal-x input surfaces (the ones that block without ending the turn)

| Tool | Input | Fires when |
| --- | --- | --- |
| `goal_question` | `{question, options?, ...}` | single drafting question |
| `goal_questionnaire` | `{questions:[{question,...}]}` | multi-question draft dialog |
| `propose_goal_draft` | `{objective, ...}` | draft confirmation dialog |
| `update_goal` | `{status:"blocked", reason?}` | goal parked awaiting user (reason is the label source) |

`goal_question`/`goal_questionnaire` block mid-turn (tool pending), so
`agent_end`/`agent_settled` never fire — no alarm exists without an explicit
hook. `update_goal(blocked)` ends the turn, so plain panes get the done alarm
anyway (do not double-notify there).

## Traps (each one has bitten already)

1. **Double alarms.** In plain panes, don't emit blocked for things
   `agent_end`/tmux-agent-notify already cover (turn-end, built-in `question`
   tool — it has its own direct handler). In herdr panes the built-in
   `question` dialog is usually caught by herdr's own TUI scan rules
   (`question_dialog`), so prefer emitting only for surfaces herdr cannot see
   (custom widgets like pi-goal-x dialogs).
2. **Idle overwrites blocked (ordering).** herdr-agent-state publishes idle on
   `agent_settled`. A blocked report for a settled turn must be deferred
   (setTimeout ≥300ms) so it lands after the idle report; the socket keeps
   send order, so "idle then blocked" ends blocked. Emitting before idle wins
   nothing.
3. **`herdr agent prompt` guard.** While a pane is reported blocked, the CLI
   refuses with `agent_blocked`. This is by design ("inspect the blocked UI").
   To drive such a pane from a script use `herdr pane send-text` +
   `herdr agent send-keys enter`. Humans typing in the pane are unaffected;
   answering clears it via the next `agent_start` (emit `{active:false}` there).
4. **herdr-agent-state gates.** It reports only when `ctx.mode === "tui"`
   (RPC/print modes are headless) and `enabled()` (herdr env vars). Its
   `session_start` is async and re-derives `agentActive` from
   `ctx.isIdle()` — don't race it within the same tick in tests.
5. **Looking-at-it suppression is expected.** tmux-agent-notify (sway window
   focus check) and herdr-focus-notify (pane focus) both stay silent while the
   user watches that pane. A "missing" alarm with the pane on screen is
   correct behavior, not a bug.
6. **HERDR_ENV leaks into child tmux servers.** If you spawn a test pane from
   a herdr shell, unset it (`tmux new-session -e HERDR_ENV= ...`) or the test
   session silently behaves as a herdr pane.
7. **Questionnaire granularity.** A pi-goal-x questionnaire is ONE tool call —
   blocked stays until all its questions are answered, even though the TUI
   shows a new dialog per question. Per-question unblock is wrong.

## Verification recipes (proven 2026-10-22)

- **Mock logic test:** load the extension with jiti
  (`~/.pi/agent/install/releases/<v>/node_modules/jiti`), mock `pi.on`/`pi.events`,
  drive `session_start`(mode tui) → `tool_call` → `tool_execution_end` →
  `agent_settled`(ctx.isIdle=()=>true) → `agent_start`; assert emit sequence.
- **herdr-agent-state socket test:** `net.createServer` on a unix socket,
  point `HERDR_SOCKET_PATH`/`HERDR_PANE_ID` at it, load
  herdr-agent-state.ts via jiti, emit `herdr:blocked`, assert
  `pane.report_agent` state=blocked arrives and lands after the settle idle.
- **Live herdr pane:** `herdr tab create --cwd <scratch>` → `herdr agent start
  <name> --kind pi --pane <ID>` → `herdr agent prompt <name> "/goal <vague topic>"
  --wait --until blocked`. `screen_detection_skipped: true` + blocked ⇒ the
  extension report drove it. `herdr agent get` shows state/seq.
- **Live plain pane:** tmux detached session running pi, same prompt, then
  check `$XDG_RUNTIME_DIR/ai-hook-notify/agents/tmux-*.json` for
  `{"state":"blocked","summary":"<question>"}` and `@ai_state=blocked`.
- pi print mode (`pi -p`) loads extensions but gates them out (mode !== tui) —
  good for load-error checks only.
