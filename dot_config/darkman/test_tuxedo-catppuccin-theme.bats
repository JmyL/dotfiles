#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  export HOME="$tmp/home"
  export TUXEDO_CONFIG_DIR="$HOME/.config/tuxedo"
  export TUXEDO_CONFIG_FILE="$TUXEDO_CONFIG_DIR/config.toml"
  script="$BATS_TEST_DIRNAME/../../.local/bin/tuxedo-catppuccin-theme"

  mkdir -p "$TUXEDO_CONFIG_DIR/themes"
  printf 'name = Catppuccin Latte\nbg = #eff1f5\n' >"$TUXEDO_CONFIG_DIR/themes/catppuccin-latte.toml"
  printf 'name = Catppuccin Macchiato\nbg = #24273a\n' >"$TUXEDO_CONFIG_DIR/themes/catppuccin-macchiato.toml"
}

teardown() {
  rm -rf "$tmp"
}

@test "rewrites the theme line for latte and keeps other keys" {
  printf 'theme = Muted Slate\ndensity = comfortable\n' >"$TUXEDO_CONFIG_FILE"
  run "$script" latte
  [ "$status" -eq 0 ]
  [ "$(sed -n 's/^theme = //p' "$TUXEDO_CONFIG_FILE")" = "Catppuccin Latte" ]
  grep -q '^density = comfortable$' "$TUXEDO_CONFIG_FILE"
}

@test "rewrites the theme line for macchiato" {
  printf 'theme = Dawn\n' >"$TUXEDO_CONFIG_FILE"
  run "$script" macchiato
  [ "$status" -eq 0 ]
  [ "$(cat "$TUXEDO_CONFIG_FILE")" = "theme = Catppuccin Macchiato" ]
}

@test "appends a theme line when the config has none" {
  printf 'density = comfortable' >"$TUXEDO_CONFIG_FILE"
  run "$script" latte
  [ "$status" -eq 0 ]
  [ "$(cat "$TUXEDO_CONFIG_FILE")" = "$(printf 'density = comfortable\ntheme = Catppuccin Latte')" ]
}

@test "creates config.toml when absent" {
  run "$script" latte
  [ "$status" -eq 0 ]
  [ "$(cat "$TUXEDO_CONFIG_FILE")" = "theme = Catppuccin Latte" ]
}

@test "rejects unknown flavors" {
  run "$script" mocha
  [ "$status" -eq 2 ]
  [ ! -f "$TUXEDO_CONFIG_FILE" ]
}

@test "fails when the flavor file is missing" {
  rm -f "$TUXEDO_CONFIG_DIR/themes/catppuccin-latte.toml"
  run "$script" latte
  [ "$status" -eq 1 ]
  [ ! -f "$TUXEDO_CONFIG_FILE" ]
}
