#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  PATH="$tmp:$PATH"
  export PROFILE_STATE="$tmp/profile-state"
  export WPCTL_LOG="$tmp/wpctl.log"
  export NOTIFY_LOG="$tmp/notify.log"
  export MENU_LOG="$tmp/menu.log"
  printf '%s\n' off >"$PROFILE_STATE"

  cat >"$tmp/pw-dump" <<'EOF'
#!/bin/sh
if [ "$(cat "$PROFILE_STATE")" != off ]; then
  cat <<'JSON'
[{"id":101,"info":{"props":{"media.class":"Audio/Sink","node.description":"Test buds","node.name":"bluez_output.test","device.id":90}}},{"id":75,"info":{"props":{"media.class":"Audio/Source","node.description":"Test buds","node.name":"bluez_input.test","device.id":90}}}]
JSON
else
  cat <<'JSON'
[{"id":75,"info":{"props":{"media.class":"Audio/Source","node.description":"Test buds","node.name":"bluez_input.test","device.id":90}}}]
JSON
fi
EOF
  chmod +x "$tmp/pw-dump"

  cat >"$tmp/pw-cli" <<'EOF'
#!/bin/sh
case "$*" in
  *' EnumProfile') cat <<'OUT'
Prop: key Spa:Pod:Object:Param:Profile:index (1), flags 00000000
  Int 131076
Prop: key Spa:Pod:Object:Param:Profile:name (2), flags 00000000
  String "a2dp-sink"
Prop: key Spa:Pod:Object:Param:Profile:index (1), flags 00000000
  Int 196865
Prop: key Spa:Pod:Object:Param:Profile:name (2), flags 00000000
  String "headset-head-unit"
OUT
    ;;
  *' Profile') printf 'Prop: key Spa:Pod:Object:Param:Profile:name (2)\n  String "%s"\n' "$(cat "$PROFILE_STATE")" ;;
esac
EOF
  chmod +x "$tmp/pw-cli"

  cat >"$tmp/wpctl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$WPCTL_LOG"
case "$1" in
  inspect)
    case "$2" in
      @DEFAULT_AUDIO_SINK@)
        if [ "$(cat "$PROFILE_STATE")" = off ]; then
          printf 'id 51, type PipeWire:Interface:Node\n'
        else
          printf 'id 101, type PipeWire:Interface:Node\n'
        fi
        ;;
      @DEFAULT_AUDIO_SOURCE@) printf 'id 75, type PipeWire:Interface:Node\n' ;;
    esac
    ;;
  set-profile)
    case "$3" in
      131076) printf '%s\n' a2dp-sink >"$PROFILE_STATE" ;;
      196865) printf '%s\n' headset-head-unit >"$PROFILE_STATE" ;;
      *) exit 9 ;;
    esac
    ;;
esac
EOF
  chmod +x "$tmp/wpctl"

  cat >"$tmp/notify-send" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$NOTIFY_LOG"
EOF
  chmod +x "$tmp/notify-send"

  script="$BATS_TEST_DIRNAME/../../.local/bin/sway-audio-switch"
  cp "$script" "$tmp/sway-audio-switch"
  script="$tmp/sway-audio-switch"
  cat >"$tmp/fzf-menu" <<'EOF'
#!/bin/sh
cat >"$MENU_LOG"
printf '%s\n' "${PROFILE_CHOICE:-Test buds (mic ready)}"
EOF
  chmod +x "$tmp/fzf-menu"
}

teardown() {
  rm -rf "$tmp"
}

@test "mic profile uses WirePlumber's numeric HFP profile index and recovers from off" {
  run "$script"

  [ "$status" -eq 0 ]
  grep -Fxq 'Laptop (speaker + mic)' "$MENU_LOG"
  grep -Fxq 'Test buds (music quality)' "$MENU_LOG"
  grep -Fxq 'Test buds (mic ready)' "$MENU_LOG"
  grep -Fxq 'set-profile 90 196865' "$WPCTL_LOG"
  grep -Fxq 'set-default 101' "$WPCTL_LOG"
  grep -Fxq 'set-default 75' "$WPCTL_LOG"
  grep -Fq 'Test buds (mic ready)' "$NOTIFY_LOG"
}

@test "music profile uses WirePlumber's numeric A2DP profile index" {
  export PROFILE_CHOICE='Test buds (music quality)'
  printf '%s\n' headset-head-unit >"$PROFILE_STATE"

  run "$script"

  [ "$status" -eq 0 ]
  [ "$(tail -n 1 "$MENU_LOG")" = 'Test buds (mic ready)' ]
  grep -Fxq 'set-profile 90 131076' "$WPCTL_LOG"
  grep -Fq 'Test buds (music quality)' "$NOTIFY_LOG"
}

@test "dictation preserves profiles and output routing" {
  run python3 "$BATS_TEST_DIRNAME/test_audio_session.py"
  [ "$status" -eq 0 ]
}

@test "only the unified audio menu has a Sway binding" {
  grep -Fq 'bindsym $mod+Shift+o exec ~/.local/bin/sway-audio-switch' "$BATS_TEST_DIRNAME/config"
  ! grep -Fq 'bindsym $mod+o ' "$BATS_TEST_DIRNAME/config"
}
