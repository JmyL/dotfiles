#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  export HOME="$tmp/home"
  export VIFM_CONFIG_DIR="$HOME/.config/vifm"
  export VIFM_THEME_STATE_PATH="$tmp/current-theme.vifm"
  export VIFM_BIN="$tmp/vifm"
  export VIFM_LOG="$tmp/vifm.log"
  script="$BATS_TEST_DIRNAME/../../.local/bin/vifm-catppuccin-theme"

  mkdir -p "$VIFM_CONFIG_DIR/colors"
  printf 'latte-theme\n' >"$VIFM_CONFIG_DIR/colors/catppuccin-latte.vifm"
  printf 'macchiato-theme\n' >"$VIFM_CONFIG_DIR/colors/catppuccin-macchiato.vifm"

  cat >"$VIFM_BIN" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${VIFM_LOG:?}"
EOF
  chmod +x "$VIFM_BIN"
}

teardown() {
  rm -rf "$tmp"
}

@test "writes latte colorscheme state and reloads vifm" {
  run "$script" latte
  [ "$status" -eq 0 ]
  [ "$(cat "$VIFM_THEME_STATE_PATH")" = "colorscheme catppuccin-latte" ]
  grep -F -- "--remote -c source $VIFM_THEME_STATE_PATH" "$VIFM_LOG"
}

@test "writes macchiato colorscheme state" {
  run "$script" macchiato
  [ "$status" -eq 0 ]
  [ "$(cat "$VIFM_THEME_STATE_PATH")" = "colorscheme catppuccin-macchiato" ]
}

@test "rejects unknown flavors" {
  run "$script" mocha
  [ "$status" -eq 2 ]
  [ ! -f "$VIFM_THEME_STATE_PATH" ]
}

@test "fails when the flavor file is missing" {
  rm -f "$VIFM_CONFIG_DIR/colors/catppuccin-latte.vifm"
  run "$script" latte
  [ "$status" -eq 1 ]
  [ ! -f "$VIFM_THEME_STATE_PATH" ]
}

@test "VIFM_REMOTE=0 skips remote reload" {
  export VIFM_REMOTE=0
  run "$script" latte
  [ "$status" -eq 0 ]
  [ "$(cat "$VIFM_THEME_STATE_PATH")" = "colorscheme catppuccin-latte" ]
  [ ! -f "$VIFM_LOG" ]
}
