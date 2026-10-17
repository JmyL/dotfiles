#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  export THEME_ORDER_LOG="$tmp/order.log"
  export HERDR_THEME_NAME_BIN="$tmp/herdr-theme-name"
  export OPENCODE_THEME_NAME_BIN="$tmp/opencode-theme-name"
  script="$BATS_TEST_DIRNAME/../../.local/share/darkman/herdr-opencode-theme"

  cat >"$HERDR_THEME_NAME_BIN" <<'EOF'
#!/usr/bin/env bash
printf 'herdr:%s\n' "$1" >>"${THEME_ORDER_LOG:?}"
EOF
  cat >"$OPENCODE_THEME_NAME_BIN" <<'EOF'
#!/usr/bin/env bash
printf 'opencode:%s\n' "$1" >>"${THEME_ORDER_LOG:?}"
EOF
  chmod +x "$HERDR_THEME_NAME_BIN" "$OPENCODE_THEME_NAME_BIN"
}

teardown() {
  rm -rf "$tmp"
}

@test "reloads OpenCode after Herdr for light mode" {
  run "$script" light
  [ "$status" -eq 0 ]
  [ "$(cat "$THEME_ORDER_LOG")" = $'herdr:light\nopencode:light' ]
}

@test "reloads OpenCode after Herdr for dark mode" {
  run "$script" dark
  [ "$status" -eq 0 ]
  [ "$(cat "$THEME_ORDER_LOG")" = $'herdr:dark\nopencode:dark' ]
}

@test "does not reload OpenCode when Herdr update fails" {
  cat >"$HERDR_THEME_NAME_BIN" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
  chmod +x "$HERDR_THEME_NAME_BIN"

  run "$script" light
  [ "$status" -eq 1 ]
  [ ! -f "$THEME_ORDER_LOG" ]
}

@test "rejects unknown modes" {
  run "$script" sepia
  [ "$status" -eq 2 ]
  [ ! -f "$THEME_ORDER_LOG" ]
}
