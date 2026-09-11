#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  PATH="$tmp:$PATH"
  script="$BATS_TEST_DIRNAME/../../.local/bin/sway-start-session"
  export DBUS_UPDATE_ACTIVATION_ENVIRONMENT="$tmp/dbus-update"
  export SYSTEMCTL="$tmp/systemctl"
  export LOG="$tmp/log"

  cat >"$tmp/dbus-update" <<'EOF'
#!/usr/bin/env bash
printf 'dbus-update %s\n' "$*" >>"${LOG:?}"
EOF
  cat >"$tmp/systemctl" <<'EOF'
#!/usr/bin/env bash
printf 'systemctl %s\n' "$*" >>"${LOG:?}"
EOF
  chmod +x "$tmp/dbus-update" "$tmp/systemctl"
}

teardown() {
  rm -rf "$tmp"
}

@test "imports environment before starting sway-session.target" {
  DISPLAY=:0 WAYLAND_DISPLAY=wayland-1 run "$script"
  [ "$status" -eq 0 ]
  grep -n . "$LOG"
  dbus_line=$(grep -n '^dbus-update ' "$LOG" | cut -d: -f1)
  import_line=$(grep -n '^systemctl --user import-environment ' "$LOG" | cut -d: -f1)
  start_line=$(grep -n '^systemctl --user start sway-session.target$' "$LOG" | cut -d: -f1)
  [ -n "$dbus_line" ]
  [ -n "$import_line" ]
  [ -n "$start_line" ]
  [ "$dbus_line" -lt "$import_line" ]
  [ "$import_line" -lt "$start_line" ]
}

@test "includes DISPLAY when it is set" {
  DISPLAY=:0 WAYLAND_DISPLAY=wayland-1 run "$script"
  [ "$status" -eq 0 ]
  grep -F -- 'dbus-update --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway XDG_SESSION_DESKTOP=sway DESKTOP_SESSION=sway DISPLAY' "$LOG"
  grep -F -- 'systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION DISPLAY' "$LOG"
}

@test "omits DISPLAY when it is unset" {
  run env -u DISPLAY WAYLAND_DISPLAY=wayland-1 "$script"
  [ "$status" -eq 0 ]
  grep -F -- 'dbus-update --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway XDG_SESSION_DESKTOP=sway DESKTOP_SESSION=sway' "$LOG"
  ! grep -F -- ' DISPLAY' "$LOG"
}
