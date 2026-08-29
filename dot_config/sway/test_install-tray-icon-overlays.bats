#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  export HOME="$tmp/home"
  export XDG_DATA_HOME="$tmp/share"
  export TRAY_REFRESH_FCITX=0
  mkdir -p "$HOME" "$XDG_DATA_HOME"
  script="$BATS_TEST_DIRNAME/../../.local/bin/install-tray-icon-overlays"
  hangul="$XDG_DATA_HOME/icons/hicolor/scalable/apps/fcitx-hangul.svg"
  keyboard="$XDG_DATA_HOME/icons/hicolor/scalable/apps/input-keyboard-symbolic.svg"
}

teardown() {
  rm -rf "$tmp"
}

hangul_fill() {
  sed -n 's/.*fill="\([^"]*\)".*/\1/p' "$hangul" | head -n 1
}

svg_fill() {
  sed -n 's/.*fill="\([^"]*\)".*/\1/p' "$1" | head -n 1
}

@test "TRAY_HAN_FILL paints the hangul glyph" {
  TRAY_HAN_FILL='#4c4f69' run "$script"
  [ "$status" -eq 0 ]
  [ "$(hangul_fill)" = "#4c4f69" ]
  [ "$(svg_fill "$keyboard")" = "#aeb4ba" ]
}

@test "uses bar-text hangul when darkman reports light" {
  mkdir -p "$tmp/bin"
  printf '%s\n' '#!/bin/sh' 'echo light' >"$tmp/bin/darkman"
  chmod +x "$tmp/bin/darkman"
  export DARKMAN="$tmp/bin/darkman"
  unset TRAY_HAN_FILL || true
  run "$script"
  [ "$status" -eq 0 ]
  [ "$(hangul_fill)" = "#4c4f69" ]
}

@test "uses white hangul when darkman reports dark" {
  mkdir -p "$tmp/bin"
  printf '%s\n' '#!/bin/sh' 'echo dark' >"$tmp/bin/darkman"
  chmod +x "$tmp/bin/darkman"
  export DARKMAN="$tmp/bin/darkman"
  unset TRAY_HAN_FILL || true
  run "$script"
  [ "$status" -eq 0 ]
  [ "$(hangul_fill)" = "#ffffff" ]
}

@test "TRAY_HAN_FILL overrides darkman" {
  mkdir -p "$tmp/bin"
  printf '%s\n' '#!/bin/sh' 'echo dark' >"$tmp/bin/darkman"
  chmod +x "$tmp/bin/darkman"
  export DARKMAN="$tmp/bin/darkman"
  TRAY_HAN_FILL='#4c4f69' run "$script"
  [ "$status" -eq 0 ]
  [ "$(hangul_fill)" = "#4c4f69" ]
}

@test "refreshes the fcitx tray by bouncing the current IM" {
  mkdir -p "$tmp/bin"
  calls="$tmp/fcitx-remote.calls"
  cat >"$tmp/bin/fcitx5-remote" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >>"$calls"
case \$1 in
--check) exit 0 ;;
-n) printf '%s\n' hangul ;;
-s) exit 0 ;;
*) exit 0 ;;
esac
EOF
  chmod +x "$tmp/bin/fcitx5-remote"
  export TRAY_REFRESH_FCITX=1
  export FCITX5_REMOTE="$tmp/bin/fcitx5-remote"
  export FCITX_TRAY_OTHER_IM=keyboard-eu
  TRAY_HAN_FILL='#ffffff' run "$script"
  [ "$status" -eq 0 ]
  expected=$(cat <<'EOF'
--check
-n
-s keyboard-eu
-s hangul
EOF
)
  [ "$(cat "$calls")" = "$expected" ]
}

@test "TRAY_REFRESH_FCITX=0 skips bouncing the IM" {
  mkdir -p "$tmp/bin"
  calls="$tmp/fcitx-remote.calls"
  : >"$calls"
  cat >"$tmp/bin/fcitx5-remote" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >>"$calls"
exit 0
EOF
  chmod +x "$tmp/bin/fcitx5-remote"
  export TRAY_REFRESH_FCITX=0
  export FCITX5_REMOTE="$tmp/bin/fcitx5-remote"
  TRAY_HAN_FILL='#ffffff' run "$script"
  [ "$status" -eq 0 ]
  [ ! -s "$calls" ]
}

@test "falls back to gdbus when fcitx5-remote is unavailable" {
  mkdir -p "$tmp/bin"
  calls="$tmp/gdbus.calls"
  cat >"$tmp/bin/gdbus" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >>"$calls"
case "\$*" in
*"CurrentInputMethodGroup"*) printf "%s\n" "('Default',)" ;;
*"InputMethodGroupInfo Default"*) printf "%s\n" "('eu', [('keyboard-eu', ''), ('hangul', '')])" ;;
*"CurrentInputMethod"*) printf "%s\n" "('hangul',)" ;;
*) printf "%s\n" "()" ;;
esac
EOF
  chmod +x "$tmp/bin/gdbus"
  export PATH="$tmp/bin:$PATH"
  export FCITX5_REMOTE="$tmp/bin/missing-fcitx5-remote"
  export TRAY_REFRESH_FCITX=1
  TRAY_HAN_FILL='#ffffff' run "$script"
  [ "$status" -eq 0 ]
  grep -q "SetCurrentIM keyboard-eu" "$calls"
  grep -q "SetCurrentIM hangul" "$calls"
}
