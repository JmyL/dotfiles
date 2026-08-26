#!/usr/bin/env bash
# Mocked-herdr tests for ~/.local/bin/herdr-tmux-edge.
set -euo pipefail

edge="${HERDR_TMUX_EDGE:-$HOME/.local/bin/herdr-tmux-edge}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

calls="$tmp/calls"
edges="$tmp/edges.json"
conf="$tmp/herdr-splits.conf"
mock="$tmp/herdr"

cat >"$mock" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$CALLS"
case "${1:-} ${2:-}" in
'pane edges')
  cat "$EDGES"
  ;;
'pane zoom' | 'pane focus')
  exit 0
  ;;
*)
  printf 'unexpected herdr invocation: %s\n' "$*" >&2
  exit 99
  ;;
esac
EOF
chmod +x "$mock"

run_edge() {
  : >"$calls"
  CALLS="$calls" EDGES="$edges" \
    HERDR_BIN_PATH="$mock" HERDR_SPLITS_CONFIG="$conf" \
    HERDR_ENV="${HERDR_ENV_FOR_TEST:-1}" \
    bash "$edge" "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  if [ -s "$calls" ]; then
    printf 'calls:\n%s\n' "$(cat "$calls")" >&2
  fi
  exit 1
}

assert_no_call() {
  if grep -q "$1" "$calls"; then
    fail "expected no call matching '$1'"
  fi
}

assert_call() {
  if ! grep -q "$1" "$calls"; then
    fail "expected a call matching '$1'"
  fi
}

printf '%s\n' '{"result":{"edges":{"left":false,"right":true,"up":true,"down":true},"zoomed":false}}' >"$edges"
printf '%s\n' 'unzoom_on_nav=false' >"$conf"

# Outside Herdr: do nothing.
HERDR_ENV_FOR_TEST=0 run_edge left
assert_no_call 'pane'

# Neighbor exists: focus that Herdr pane.
run_edge left
assert_call 'pane focus --direction left --current'
assert_no_call 'pane zoom'

# Zoomed + unzoom disabled: stay put.
printf '%s\n' '{"result":{"edges":{"left":true,"right":true,"up":true,"down":true},"zoomed":true}}' >"$edges"
run_edge left
assert_no_call 'pane zoom'
assert_no_call 'pane focus'

# Zoomed + unzoom enabled: unzoom, then focus.
printf '%s\n' 'unzoom_on_nav=true' >"$conf"
run_edge right
assert_call 'pane zoom --off --current'
assert_call 'pane focus --direction right --current'

# Unknown direction.
if bash "$edge" sideways >/dev/null 2>&1; then
  fail 'expected unknown direction to fail'
fi

printf 'ok\n'
