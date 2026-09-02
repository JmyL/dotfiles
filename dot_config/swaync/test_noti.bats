#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  PATH="$tmp:$PATH"
  script="$BATS_TEST_DIRNAME/../../.local/bin/noti"
  export NOTIFY_SEND="$tmp/notify-send"
  export CANBERRA_GTK_PLAY="$tmp/canberra-gtk-play"
  export NOTIFY_LOG="$tmp/notify.log"
  export SOUND_LOG="$tmp/sound.log"

  cat >"$NOTIFY_SEND" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"${NOTIFY_LOG:?}"
EOF
  chmod +x "$NOTIFY_SEND"

  cat >"$CANBERRA_GTK_PLAY" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"${SOUND_LOG:?}"
EOF
  chmod +x "$CANBERRA_GTK_PLAY"
}

teardown() {
  rm -rf "$tmp"
}

wait_for_sound() {
  local i
  for i in $(seq 1 40); do
    if [[ -s "${SOUND_LOG:-}" ]]; then
      return 0
    fi
    sleep 0.05
  done
  return 1
}

@test "defaults the notification title to done" {
  run "$script"
  [ "$status" -eq 0 ]
  [ "$(cat "$NOTIFY_LOG")" = "--
done" ]
  wait_for_sound
  [ "$(cat "$SOUND_LOG")" = "-i
complete" ]
}

@test "uses the given arguments as the title" {
  run "$script" deploy finished
  [ "$status" -eq 0 ]
  [ "$(cat "$NOTIFY_LOG")" = "--
deploy finished" ]
  wait_for_sound
  [ "$(cat "$SOUND_LOG")" = "-i
complete" ]
}

@test "still notifies when the sound command is missing" {
  export CANBERRA_GTK_PLAY="$tmp/missing-canberra"
  run "$script" ok
  [ "$status" -eq 0 ]
  [ "$(cat "$NOTIFY_LOG")" = "--
ok" ]
  [ ! -f "$SOUND_LOG" ]
}

@test "fails when notify-send is missing" {
  export NOTIFY_SEND="$tmp/missing-notify-send"
  run "$script"
  [ "$status" -ne 0 ]
  [ ! -f "$NOTIFY_LOG" ]
}
