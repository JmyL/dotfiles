#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  PATH="$tmp:$PATH"
  script="$BATS_TEST_DIRNAME/../../.local/bin/sway-recover-display"

  cat >"$tmp/swaymsg" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${SWAYMSG_LOG:?}"
if [[ "${1:-}" == -t && "${2:-}" == get_outputs ]]; then
  printf '%s\n' '[{"name":"HDMI-A-1"},{"name":"eDP-1"}]'
fi
EOF
  chmod +x "$tmp/swaymsg"

  cat >"$tmp/pkill" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${PKILL_LOG:?}"
EOF
  chmod +x "$tmp/pkill"

  cat >"$tmp/notify-send" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >>"${NOTIFY_LOG:?}"
EOF
  chmod +x "$tmp/notify-send"

  export SWAYMSG="$tmp/swaymsg"
  export PKILL="$tmp/pkill"
  export SWAYMSG_LOG="$tmp/swaymsg.log"
  export PKILL_LOG="$tmp/pkill.log"
  export NOTIFY_LOG="$tmp/notify.log"
}

teardown() {
  rm -rf "$tmp"
}

@test "enables eDP with space-separated position and disables HDMI" {
  run "$script" --quiet
  [ "$status" -eq 0 ]
  grep -qx -- '-x kanshi' "$PKILL_LOG"
  grep -Fqx -- '-t get_outputs -r' "$SWAYMSG_LOG"
  grep -Fqx -- 'output HDMI-A-1 disable' "$SWAYMSG_LOG"
  grep -Fqx -- 'output eDP-1 enable power on position 0 0' "$SWAYMSG_LOG"
  grep -Fqx -- 'output * power on' "$SWAYMSG_LOG"
  ! grep -F -- 'position 0,0' "$SWAYMSG_LOG"
  [ ! -f "$NOTIFY_LOG" ]
}

@test "notifies unless --quiet" {
  run "$script"
  [ "$status" -eq 0 ]
  [ -f "$NOTIFY_LOG" ]
  grep -q 'Display recovery' "$NOTIFY_LOG"
}
