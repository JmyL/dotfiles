#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  PATH="$tmp:$PATH"
  script="$BATS_TEST_DIRNAME/../../.local/bin/waybar-sway-bar"
  export XDG_RUNTIME_DIR="$tmp/runtime"
  export HOME="$tmp/home"
  export WAYBAR_ENV_LOG="$tmp/waybar.env"
  mkdir -p "$XDG_RUNTIME_DIR" "$HOME"

  cat >"$tmp/waybar" <<'EOF'
#!/usr/bin/env bash
env >"${WAYBAR_ENV_LOG:?}"
exit 0
EOF
  cat >"$tmp/swaymsg" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' '[{"name":"HDMI-A-1","active": true}]'
EOF
  chmod +x "$tmp/waybar" "$tmp/swaymsg"
}

teardown() {
  rm -rf "$tmp"
}

@test "unsets WAYLAND_SOCKET in the waybar child" {
  timeout --signal=KILL 1 env WAYLAND_SOCKET=172 WAYLAND_DISPLAY=wayland-1 DISPLAY=:0 \
    "$script" -b bar-0 || true
  [ -s "$WAYBAR_ENV_LOG" ]
  ! grep -q '^WAYLAND_SOCKET=' "$WAYBAR_ENV_LOG"
  grep -Fqx -- 'WAYLAND_DISPLAY=wayland-1' "$WAYBAR_ENV_LOG"
}
