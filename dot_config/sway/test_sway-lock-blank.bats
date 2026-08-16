#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  PATH="$tmp:$PATH"
  export XDG_RUNTIME_DIR="$tmp/run"
  mkdir -p "$XDG_RUNTIME_DIR"

  export SWAYLOCK="$tmp/swaylock"
  export SWAYIDLE="$tmp/swayidle"
  export SWAYMSG="$tmp/swaymsg"
  export SWAY_LOCK_FLAG="$tmp/manual-lock.pid"
  export SWAY_LOCK_WALLPAPER="$tmp/missing-wallpaper.jpg"
  export SWAYLOCK_LOG="$tmp/swaylock.log"
  export SWAYIDLE_LOG="$tmp/swayidle.log"
  export SWAYMSG_LOG="$tmp/swaymsg.log"
  export SWAYLOCK_STATUS=0

  cat >"$SWAYLOCK" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >>"${SWAYLOCK_LOG:?}"
exit "${SWAYLOCK_STATUS:-0}"
EOF
  chmod +x "$SWAYLOCK"

  cat >"$SWAYIDLE" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >>"${SWAYIDLE_LOG:?}"
exec sleep 60
EOF
  chmod +x "$SWAYIDLE"

  cat >"$SWAYMSG" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${SWAYMSG_LOG:?}"
EOF
  chmod +x "$SWAYMSG"

  lock_script="$BATS_TEST_DIRNAME/../../.local/bin/sway-lock-blank"
  active_script="$BATS_TEST_DIRNAME/../../.local/bin/manual-lock-active"
}

teardown() {
  rm -rf "$tmp"
}

@test "locks with wallpaper, blanks after 10s, then powers on and clears the flag" {
  : >"$SWAY_LOCK_WALLPAPER"
  run "$lock_script"
  [ "$status" -eq 0 ]
  [ ! -f "$SWAY_LOCK_FLAG" ]

  readarray -t lock_args <"$SWAYLOCK_LOG"
  [ "${lock_args[0]}" = -i ]
  [ "${lock_args[1]}" = "$SWAY_LOCK_WALLPAPER" ]
  [ "${lock_args[2]}" = -s ]
  [ "${lock_args[3]}" = fill ]

  readarray -t idle_args <"$SWAYIDLE_LOG"
  [ "${idle_args[0]}" = -w ]
  [ "${idle_args[1]}" = timeout ]
  [ "${idle_args[2]}" = 10 ]
  [ "${idle_args[3]}" = "$SWAYMSG \"output * power off\"" ]
  [ "${idle_args[4]}" = resume ]
  [ "${idle_args[5]}" = "$SWAYMSG \"output * power on\"" ]

  grep -Fqx -- 'output * power on' "$SWAYMSG_LOG"
}

@test "still clears the flag and powers on if swaylock fails" {
  SWAYLOCK_STATUS=1
  run "$lock_script"
  [ "$status" -eq 1 ]
  [ ! -f "$SWAY_LOCK_FLAG" ]
  grep -Fqx -- 'output * power on' "$SWAYMSG_LOG"
}

@test "does not start a second lock while one is already active" {
  sleep 30 &
  printf '%s\n' "$!" >"$SWAY_LOCK_FLAG"
  run "$lock_script"
  kill "$!" 2>/dev/null || true
  wait "$!" 2>/dev/null || true
  [ "$status" -eq 0 ]
  [ ! -f "$SWAYLOCK_LOG" ]
  [ ! -f "$SWAYIDLE_LOG" ]
}

@test "manual-lock-active is true only for a live flag pid" {
  run "$active_script"
  [ "$status" -eq 1 ]

  printf '%s\n' '999999' >"$SWAY_LOCK_FLAG"
  run "$active_script"
  [ "$status" -eq 1 ]

  sleep 30 &
  printf '%s\n' "$!" >"$SWAY_LOCK_FLAG"
  run "$active_script"
  status_live="$status"
  kill "$!" 2>/dev/null || true
  wait "$!" 2>/dev/null || true
  [ "$status_live" -eq 0 ]
}
