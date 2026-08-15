#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  PATH="$tmp:$PATH"
  export HOME="$tmp/home"
  export XDG_VIDEOS_DIR="$tmp/videos"
  export XDG_RUNTIME_DIR="$tmp/run"
  export WAYBAR_STATE_PATH="$tmp/waybar-state.css"
  export WAYBAR_STYLE_PATH="$tmp/waybar-style.css"
  export SWAY_RECORDING_RNNOISE_PLUGIN="$tmp/librnnoise_ladspa.so"
  export SWAY_RECORDING_RNNOISE_IN=sway-recording-rnnoise-in
  export SWAY_RECORDING_RNNOISE_OUT=sway-recording-rnnoise
  export SWAY_RECORDING_MIX_SOURCE=sway-recording-mix
  export SWAY_RECORDING_MIX_SINK=sway-recording-mix-sink
  export PORTS_FILE="$tmp/ports"
  export LOOPBACK_LOG="$tmp/pw-loopback.log"
  export PIPEWIRE_LOG="$tmp/pipewire.log"
  export LINK_LOG="$tmp/pw-link.log"
  export RECORDER_LOG="$tmp/wf-recorder.log"
  mkdir -p "$HOME" "$XDG_VIDEOS_DIR" "$XDG_RUNTIME_DIR"
  : >"$WAYBAR_STYLE_PATH"
  : >"$SWAY_RECORDING_RNNOISE_PLUGIN"
  printf '%s\n' \
    'mock-mic:capture_MONO' \
    'mock-sink:monitor_FL' \
    'mock-sink:monitor_FR' >"$PORTS_FILE"

  cat >"$tmp/wpctl" <<'EOF'
#!/bin/sh
case " $* " in
*"@DEFAULT_AUDIO_SOURCE@"*) printf '  * node.name = "mock-mic"\n' ;;
*"@DEFAULT_AUDIO_SINK@"*) printf '  * node.name = "mock-sink"\n' ;;
*) exit 1 ;;
esac
EOF
  chmod +x "$tmp/wpctl"

  cat >"$tmp/pw-loopback" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"${LOOPBACK_LOG:?}"
printf '%s\n' \
  'sway-recording-mix-sink:playback_FL' \
  'sway-recording-mix-sink:playback_FR' \
  'sway-recording-mix:capture_FL' \
  'sway-recording-mix:capture_FR' >>"${PORTS_FILE:?}"
sleep 30
EOF
  chmod +x "$tmp/pw-loopback"

  cat >"$tmp/pipewire" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"${PIPEWIRE_LOG:?}"
printf '%s\n' \
  'sway-recording-rnnoise-in:playback_MONO' \
  'sway-recording-rnnoise:capture_MONO' >>"${PORTS_FILE:?}"
sleep 30
EOF
  chmod +x "$tmp/pipewire"

  cat >"$tmp/pw-link" <<'EOF'
#!/bin/sh
if [ "${1:-}" = -io ]; then
  cat "${PORTS_FILE:?}"
  exit 0
fi
printf '%s -> %s\n' "$1" "$2" >>"${LINK_LOG:?}"
EOF
  chmod +x "$tmp/pw-link"

  cat >"$tmp/wf-recorder" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"${RECORDER_LOG:?}"
sleep 30
EOF
  chmod +x "$tmp/wf-recorder"

  cat >"$tmp/swaymsg" <<'EOF'
#!/bin/sh
printf '%s\n' '[{"focused":true,"output":"DP-1"}]'
EOF
  chmod +x "$tmp/swaymsg"

  cat >"$tmp/slurp" <<'EOF'
#!/bin/sh
printf '%s\n' '10,20 640x480'
EOF
  chmod +x "$tmp/slurp"

  cat >"$tmp/notify-send" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >>"${NOTIFY_LOG:?}"
EOF
  chmod +x "$tmp/notify-send"

  export WPCTL="$tmp/wpctl"
  export PW_LOOPBACK="$tmp/pw-loopback"
  export PIPEWIRE="$tmp/pipewire"
  export PW_LINK="$tmp/pw-link"
  export WF_RECORDER="$tmp/wf-recorder"
  export SWAYMSG="$tmp/swaymsg"
  export SLURP="$tmp/slurp"
  export NOTIFY_LOG="$tmp/notify.log"
  script="$BATS_TEST_DIRNAME/../../.local/bin/sway-recording"
}

teardown() {
  if [ -n "${tmp:-}" ]; then
    for pidfile in "$XDG_RUNTIME_DIR"/wf-recorder.pid \
      "$XDG_RUNTIME_DIR"/sway-recording-mix.pid \
      "$XDG_RUNTIME_DIR"/sway-recording-rnnoise.pid; do
      if [ -s "$pidfile" ]; then
        kill "$(cat "$pidfile")" 2>/dev/null || true
      fi
    done
    rm -rf "$tmp"
  fi
}

assert_link_order() {
  [ -f "$LINK_LOG" ]
  grep -Fxq 'mock-mic:capture_MONO -> sway-recording-rnnoise-in:playback_MONO' "$LINK_LOG"
  grep -Fxq 'sway-recording-rnnoise:capture_MONO -> sway-recording-mix-sink:playback_FL' "$LINK_LOG"
  grep -Fxq 'sway-recording-rnnoise:capture_MONO -> sway-recording-mix-sink:playback_FR' "$LINK_LOG"
  grep -Fxq 'mock-sink:monitor_FL -> sway-recording-mix-sink:playback_FL' "$LINK_LOG"
  grep -Fxq 'mock-sink:monitor_FR -> sway-recording-mix-sink:playback_FR' "$LINK_LOG"
  if grep -q 'mock-mic:.* -> sway-recording-mix-sink:' "$LINK_LOG"; then
    echo "raw mic was linked into the mix" >&2
    return 1
  fi
}

@test "full routes mic through RNNoise then into the mix" {
  run "$script" full
  [ "$status" -eq 0 ]
  [ -s "$PIPEWIRE_LOG" ]
  grep -Fq -- '-c' "$PIPEWIRE_LOG"
  grep -Fq "$XDG_RUNTIME_DIR/sway-recording-rnnoise.conf" "$PIPEWIRE_LOG"
  grep -Fq "plugin = \"$SWAY_RECORDING_RNNOISE_PLUGIN\"" "$XDG_RUNTIME_DIR/sway-recording-rnnoise.conf"
  grep -Fq -- '--audio=sway-recording-mix' "$RECORDER_LOG"
  assert_link_order
}

@test "area uses the same RNNoise mix path" {
  run "$script" area
  [ "$status" -eq 0 ]
  grep -Fq -- '-g' "$RECORDER_LOG"
  assert_link_order
}

@test "missing RNNoise plugin fails without starting the mix" {
  rm -f "$SWAY_RECORDING_RNNOISE_PLUGIN"
  run "$script" full
  [ "$status" -eq 1 ]
  [ ! -f "$LOOPBACK_LOG" ]
  [ ! -f "$PIPEWIRE_LOG" ]
  grep -q 'RNNoise plugin missing' "$NOTIFY_LOG"
}

@test "stop tears down mix and RNNoise" {
  run "$script" full
  [ "$status" -eq 0 ]
  mix_pid=$(cat "$XDG_RUNTIME_DIR/sway-recording-mix.pid")
  rnnoise_pid=$(cat "$XDG_RUNTIME_DIR/sway-recording-rnnoise.pid")
  kill -0 "$mix_pid"
  kill -0 "$rnnoise_pid"
  run "$script" stop
  [ "$status" -eq 0 ]
  ! kill -0 "$mix_pid" 2>/dev/null
  ! kill -0 "$rnnoise_pid" 2>/dev/null
  [ ! -f "$XDG_RUNTIME_DIR/sway-recording-mix.pid" ]
  [ ! -f "$XDG_RUNTIME_DIR/sway-recording-rnnoise.pid" ]
  [ ! -f "$XDG_RUNTIME_DIR/sway-recording-rnnoise.conf" ]
}

@test "unknown command exits 2" {
  run "$script" nope
  [ "$status" -eq 2 ]
}
