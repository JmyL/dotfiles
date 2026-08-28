#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  export HOME="$tmp/home"
  export XDG_DATA_HOME="$tmp/share"
  mkdir -p "$HOME" "$XDG_DATA_HOME"
  script="$BATS_TEST_DIRNAME/../../.local/bin/install-tray-icon-overlays"
  hangul="$XDG_DATA_HOME/icons/hicolor/scalable/apps/fcitx-hangul.svg"
}

teardown() {
  rm -rf "$tmp"
}

hangul_fill() {
  sed -n 's/.*fill="\([^"]*\)".*/\1/p' "$hangul" | head -n 1
}

@test "TRAY_HAN_FILL paints the hangul glyph" {
  TRAY_HAN_FILL='#4c4f69' run "$script"
  [ "$status" -eq 0 ]
  [ "$(hangul_fill)" = "#4c4f69" ]
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
