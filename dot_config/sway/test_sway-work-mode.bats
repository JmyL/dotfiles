#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  PATH="$tmp:$PATH"
  export HOME="$tmp/home"
  export SWAYMSG="$tmp/swaymsg"
  export NOTIFY_SEND="$tmp/notify-send"
  export SWAYMSG_LOG="$tmp/swaymsg.log"
  export NOTIFY_LOG="$tmp/notify.log"
  mkdir -p "$HOME/.local/bin/work"
  script="$BATS_TEST_DIRNAME/../../.local/bin/sway-work-mode"

  cat >"$SWAYMSG" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"${SWAYMSG_LOG:?}"
EOF
  chmod +x "$SWAYMSG"

  cat >"$NOTIFY_SEND" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"${NOTIFY_LOG:?}"
EOF
  chmod +x "$NOTIFY_SEND"
}

teardown() {
  rm -rf "$tmp"
}

@test "enters quoted work mode when launcher exists" {
  printf '#!/bin/sh\n' >"$HOME/.local/bin/work/ree-goodmorning-launch"
  chmod +x "$HOME/.local/bin/work/ree-goodmorning-launch"

  run "$script"
  [ "$status" -eq 0 ]
  [ "$(cat "$SWAYMSG_LOG")" = 'mode "Work: [g]oodmorning [r]eservation [d]eploy [s]ession [o]pen [c]opy [q]uit"' ]
  [ ! -f "$NOTIFY_LOG" ]
}

@test "notifies when work tools are missing" {
  run "$script"
  [ "$status" -eq 0 ]
  [ ! -f "$SWAYMSG_LOG" ]
  [ "$(cat "$NOTIFY_LOG")" = "Work tools not installed $HOME/.local/bin/work is unavailable" ]
}

@test "notifies when launcher exists but is not executable" {
  printf '#!/bin/sh\n' >"$HOME/.local/bin/work/ree-goodmorning-launch"
  chmod -x "$HOME/.local/bin/work/ree-goodmorning-launch"

  run "$script"
  [ "$status" -eq 0 ]
  [ ! -f "$SWAYMSG_LOG" ]
  [ "$(cat "$NOTIFY_LOG")" = "Work tools not installed $HOME/.local/bin/work is unavailable" ]
}
