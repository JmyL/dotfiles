#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  export HOME="$tmp/home"
  mkdir -p "$HOME/.config/waybar/themes"
  export WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
  export WAYBAR_THEME_STATE_PATH="$tmp/theme-state.css"
  export WAYBAR_STYLE_PATH="$tmp/style.css"
  script="$BATS_TEST_DIRNAME/../../.local/bin/waybar-catppuccin-theme"

  printf 'latte-css\n' >"$WAYBAR_CONFIG_DIR/themes/catppuccin-latte.css"
  printf 'macchiato-css\n' >"$WAYBAR_CONFIG_DIR/themes/catppuccin-macchiato.css"
  printf 'style-body\n' >"$WAYBAR_STYLE_PATH"
}

teardown() {
  rm -rf "$tmp"
}

@test "copies latte onto the theme state file and pokes style.css" {
  run "$script" latte
  [ "$status" -eq 0 ]
  [ "$(cat "$WAYBAR_THEME_STATE_PATH")" = "latte-css" ]
  [ "$(cat "$WAYBAR_STYLE_PATH")" = "style-body" ]
}

@test "copies macchiato onto the theme state file" {
  run "$script" macchiato
  [ "$status" -eq 0 ]
  [ "$(cat "$WAYBAR_THEME_STATE_PATH")" = "macchiato-css" ]
}

@test "rejects unknown flavors" {
  run "$script" mocha
  [ "$status" -eq 2 ]
  [ ! -f "$WAYBAR_THEME_STATE_PATH" ]
}

@test "fails when the flavor file is missing" {
  rm -f "$WAYBAR_CONFIG_DIR/themes/catppuccin-latte.css"
  run "$script" latte
  [ "$status" -eq 1 ]
  [ ! -f "$WAYBAR_THEME_STATE_PATH" ]
}

@test "latte theme colors idle inhibitor by activation class" {
  latte="$BATS_TEST_DIRNAME/themes/catppuccin-latte.css"
  grep -q '#custom-idle_inhibitor.activated' "$latte"
  grep -q '#custom-idle_inhibitor.deactivated' "$latte"
  ! grep -qE 'window#waybar #custom-idle_inhibitor,' "$latte"
}

@test "WAYBAR_POKE=0 skips poking style.css" {
  export WAYBAR_POKE=0
  printf 'untouched\n' >"$WAYBAR_STYLE_PATH"
  run "$script" latte
  [ "$status" -eq 0 ]
  [ "$(cat "$WAYBAR_THEME_STATE_PATH")" = "latte-css" ]
  [ "$(cat "$WAYBAR_STYLE_PATH")" = "untouched" ]
}
