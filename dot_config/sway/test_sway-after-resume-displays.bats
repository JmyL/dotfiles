#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  PATH="$tmp:$PATH"
  script="$BATS_TEST_DIRNAME/../../.local/bin/sway-after-resume-displays"
  mkdir -p "$tmp/drm"

  cat >"$tmp/swaymsg" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${SWAYMSG_LOG:?}"
if [[ "${1:-}" == -t && "${2:-}" == get_outputs ]]; then
  cat "${SWAY_OUTPUTS_JSON:?}"
fi
EOF
  chmod +x "$tmp/swaymsg"

  cat >"$tmp/pgrep" <<'EOF'
#!/usr/bin/env bash
exit "${PGREP_STATUS:-1}"
EOF
  chmod +x "$tmp/pgrep"

  cat >"$tmp/recover" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >>"${RECOVER_LOG:?}"
EOF
  chmod +x "$tmp/recover"

  export SWAYMSG="$tmp/swaymsg"
  export PGREP="$tmp/pgrep"
  export RECOVER_DISPLAY="$tmp/recover"
  export DRM_DIR="$tmp/drm"
  export SWAYMSG_LOG="$tmp/swaymsg.log"
  export RECOVER_LOG="$tmp/recover.log"
  export SWAY_OUTPUTS_JSON="$tmp/outputs.json"
  export SWAY_AFTER_RESUME_POLL=0
  export SWAY_AFTER_RESUME_ENABLE_TRIES=2
  export PGREP_STATUS=1
}

teardown() {
  rm -rf "$tmp"
}

write_outputs() {
  printf '%s\n' "$1" >"$SWAY_OUTPUTS_JSON"
}

@test "after unlock starts kanshi when HDMI becomes active" {
  write_outputs '[{"name":"eDP-1","active":true},{"name":"HDMI-A-1","active":true}]'
  run "$script" --after-unlock
  [ "$status" -eq 0 ]
  grep -Fqx -- 'output HDMI-A-1 enable power on' "$SWAYMSG_LOG"
  grep -Fqx -- 'exec kanshi' "$SWAYMSG_LOG"
}

@test "after unlock skips kanshi when HDMI is plugged but stays inactive" {
  mkdir -p "$DRM_DIR/card2-HDMI-A-1"
  printf '%s\n' connected >"$DRM_DIR/card2-HDMI-A-1/status"
  write_outputs '[{"name":"eDP-1","active":true},{"name":"HDMI-A-1","active":false}]'
  run "$script" --after-unlock
  [ "$status" -eq 0 ]
  grep -Fqx -- 'output HDMI-A-1 enable power on' "$SWAYMSG_LOG"
  ! grep -Fqx -- 'exec kanshi' "$SWAYMSG_LOG"
}

@test "after unlock starts kanshi when no external is plugged" {
  mkdir -p "$DRM_DIR/card2-HDMI-A-1"
  printf '%s\n' disconnected >"$DRM_DIR/card2-HDMI-A-1/status"
  write_outputs '[{"name":"eDP-1","active":true}]'
  run "$script" --after-unlock
  [ "$status" -eq 0 ]
  grep -Fqx -- 'exec kanshi' "$SWAYMSG_LOG"
}

@test "resume entry recovers then execs the unlock waiter" {
  write_outputs '[]'
  run "$script"
  [ "$status" -eq 0 ]
  grep -Fqx -- '--quiet' "$RECOVER_LOG"
  grep -Fqx -- '--blank-externals' "$RECOVER_LOG"
  grep -F -- '--after-unlock' "$SWAYMSG_LOG"
}
