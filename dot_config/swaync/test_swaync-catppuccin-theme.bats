#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  export HOME="$tmp/home"
  mkdir -p "$HOME/.config/swaync/themes" "$HOME/.local/bin"
  export SWAYNC_CONFIG_DIR="$HOME/.config/swaync"
  export SWAYNC_CLIENT="$tmp/swaync-client"
  export CLIENT_LOG="$tmp/client.log"
  script="$BATS_TEST_DIRNAME/../../.local/bin/swaync-catppuccin-theme"

  printf 'latte-css\n' >"$SWAYNC_CONFIG_DIR/themes/catppuccin-latte.css"
  printf 'macchiato-css\n' >"$SWAYNC_CONFIG_DIR/themes/catppuccin-macchiato.css"

  cat >"$SWAYNC_CLIENT" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${CLIENT_LOG:?}"
exit "${CLIENT_FAIL:-0}"
EOF
  chmod +x "$SWAYNC_CLIENT"
}

teardown() {
  rm -rf "$tmp"
}

@test "copies latte onto style.css and reloads" {
  run "$script" latte
  [ "$status" -eq 0 ]
  [ "$(cat "$SWAYNC_CONFIG_DIR/style.css")" = "latte-css" ]
  [ "$(cat "$CLIENT_LOG")" = "-R -rs -sw" ]
}

@test "copies macchiato onto style.css" {
  run "$script" macchiato
  [ "$status" -eq 0 ]
  [ "$(cat "$SWAYNC_CONFIG_DIR/style.css")" = "macchiato-css" ]
}

@test "rejects unknown flavors" {
  run "$script" mocha
  [ "$status" -eq 2 ]
  [ ! -f "$SWAYNC_CONFIG_DIR/style.css" ]
}

@test "fails when the flavor file is missing" {
  rm -f "$SWAYNC_CONFIG_DIR/themes/catppuccin-latte.css"
  run "$script" latte
  [ "$status" -eq 1 ]
  [ ! -f "$SWAYNC_CONFIG_DIR/style.css" ]
}

@test "SWAYNC_RELOAD=0 skips swaync-client" {
  export SWAYNC_RELOAD=0
  run "$script" latte
  [ "$status" -eq 0 ]
  [ "$(cat "$SWAYNC_CONFIG_DIR/style.css")" = "latte-css" ]
  [ ! -f "$CLIENT_LOG" ]
}

@test "reload failure does not undo a successful copy" {
  export CLIENT_FAIL=1
  run "$script" latte
  [ "$status" -eq 0 ]
  [ "$(cat "$SWAYNC_CONFIG_DIR/style.css")" = "latte-css" ]
}
