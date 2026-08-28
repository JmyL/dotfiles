#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  export CURSOR_TERM_THEME_FILE="$tmp/cursor-term-theme"
  export TMUX_BIN="$tmp/tmux"
  export PGREP_BIN="$tmp/pgrep"
  export SYSTEMCTL_BIN="$tmp/systemctl"
  export TMUX_LOG="$tmp/tmux.log"
  export PGREP_LOG="$tmp/pgrep.log"
  export SYSTEMCTL_LOG="$tmp/systemctl.log"
  export PGREP_FAIL=1
  script="$BATS_TEST_DIRNAME/../../.local/bin/cursor-cli-term-theme"
  bashrc="$BATS_TEST_DIRNAME/../../.bashrc.d/cursor-term-theme"

  cat >"$TMUX_BIN" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${TMUX_LOG:?}"
EOF
  cat >"$PGREP_BIN" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${PGREP_LOG:?}"
exit "${PGREP_FAIL:-1}"
EOF
  cat >"$SYSTEMCTL_BIN" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${SYSTEMCTL_LOG:?}"
EOF
  chmod +x "$TMUX_BIN" "$PGREP_BIN" "$SYSTEMCTL_BIN"
}

teardown() {
  rm -rf "$tmp"
}

@test "maps darkman light to inverted TERM_THEME=dark" {
  run "$script" light
  [ "$status" -eq 0 ]
  [ "$(cat "$CURSOR_TERM_THEME_FILE")" = "dark" ]
  [ -f "$SYSTEMCTL_LOG" ]
  grep -F -- "--user set-environment TERM_THEME=dark" "$SYSTEMCTL_LOG"
  [ ! -f "$TMUX_LOG" ]
}

@test "maps darkman dark to inverted TERM_THEME=light and updates tmux" {
  export PGREP_FAIL=0
  run "$script" dark
  [ "$status" -eq 0 ]
  [ "$(cat "$CURSOR_TERM_THEME_FILE")" = "light" ]
  grep -F -- "set-environment -g TERM_THEME light" "$TMUX_LOG"
  grep -F -- "--user set-environment TERM_THEME=light" "$SYSTEMCTL_LOG"
}

@test "tmux failure does not undo a successful write" {
  export PGREP_FAIL=0
  cat >"$TMUX_BIN" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${TMUX_LOG:?}"
exit 1
EOF
  chmod +x "$TMUX_BIN"
  run "$script" light
  [ "$status" -eq 0 ]
  [ "$(cat "$CURSOR_TERM_THEME_FILE")" = "dark" ]
}

@test "rejects unknown themes" {
  run "$script" latte
  [ "$status" -eq 2 ]
  [ ! -f "$CURSOR_TERM_THEME_FILE" ]
}

@test "bashrc exports TERM_THEME from the state file" {
  printf 'light\n' >"$CURSOR_TERM_THEME_FILE"
  unset TERM_THEME
  # shellcheck disable=SC1090
  source "$bashrc"
  [ "$TERM_THEME" = "light" ]
}

@test "bashrc inverts darkman when the state file is missing" {
  PATH="$tmp:$PATH"
  cat >"$tmp/darkman" <<'EOF'
#!/usr/bin/env bash
echo dark
EOF
  chmod +x "$tmp/darkman"
  unset TERM_THEME
  # shellcheck disable=SC1090
  source "$bashrc"
  [ "$TERM_THEME" = "light" ]
}
