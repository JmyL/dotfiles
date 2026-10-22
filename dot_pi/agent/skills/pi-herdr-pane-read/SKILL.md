---
name: pi-herdr-pane-read
description: Use when the user asks to read, check, or inspect a neighboring herdr pane or its output — triggers include "옆 pane 읽어 줘", "옆 pane에서 에러났네", "pane 확인해 줘", "pane 출력 봐 줘", "다른 pane", "neighbor pane", or reporting an error they saw in another pane without pasting it. Covers herdr pane read/wait-output usage, pane selection, and safety rules.
---

# Reading neighboring herdr panes

How to find and read another pane's output on the user's request, and the traps
that caused wrong reads.

## Guard

Run only inside herdr:

```bash
test "${HERDR_ENV:-}" = 1
```

If it fails, say you are not running inside Herdr and stop. If `herdr` is not
on PATH, say so and stop.

## 1. Find the target pane

```bash
herdr pane list            # JSON pane_list; parse with jq/python — never guess IDs
herdr pane current         # the pane you (the agent) are running in
```

Selection order:

1. **Same workspace/tab** as the current pane (`tab_id` equal) and
   `agent_status: "unknown"` (plain shell panes). The user's "옆 pane" is
   almost always one of these.
2. If several candidates remain, pick by `terminal_title` (e.g. `root@ts-de-ber-ares: ~`)
   or `foreground_cwd`; show the shortlist with titles and ask only if still
   ambiguous.
3. Never derive the pane ID from sidebar order or from an example — read it
   from the JSON response.

## 2. Read the output

```bash
# Logs / command transcripts (soft wraps joined): the default for "에러났네"
herdr pane read <pane_id> --source recent-unwrapped --lines 150 --format text

# What is on screen right now
herdr pane read <pane_id> --source visible

# Plain bottom-buffer snapshot (agent detection style)
herdr pane read <pane_id> --source detection
```

- `recent-unwrapped` + `--lines 150` is the right first call for logs and error
  messages; increase `--lines` (up to the pane's scrollback) if the tail does
  not contain the failure.
- Increase only as needed: a long read floods the transcript with secrets
  (tokens, hostnames, history). Summarize the error and quote only the
  relevant lines; do not dump whole history.
- If the read still misses it, ask the user to paste the error or write it to a
  temp file — do not keep blind-scrolling.

## 3. Wait for new output (optional)

```bash
herdr pane wait-output <pane_id> --match "<literal text>" --timeout 120000
```

`--match` is a literal substring (`--regex` for a Rust regex). The snapshot is
searched immediately, so already-present output matches at once.

## Traps

- A successful `herdr pane get <id>` returns **metadata only** — it does not
  show the buffer. Use `pane read`.
- Alternate-screen applications (vim, htop, `watch`, TUIs) do not enter host
  scrollback; their rows are not recoverable via `recent-unwrapped`.
- Do not `send-text` / `send-keys` / `close` panes unless the user explicitly
  asked for exactly that action.
- Do not focus or zoom the pane just to read it; `pane read` does not need it.
