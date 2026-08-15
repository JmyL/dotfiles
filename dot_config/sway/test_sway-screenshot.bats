#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  PATH="$tmp:$PATH"
  export HOME="$tmp/home"
  export XDG_PICTURES_DIR="$tmp/pictures"
  unset XDG_SCREENSHOTS_DIR
  mkdir -p "$HOME" "$XDG_PICTURES_DIR"

  cat >"$tmp/grimshot" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"${GRIMSHOT_LOG:?}"
mkdir -p "$(dirname "${4:-/tmp/missing}")"
: >"${4:-/tmp/missing}"
EOF
  chmod +x "$tmp/grimshot"

  cat >"$tmp/date" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' '20260815-173000-123'
EOF
  chmod +x "$tmp/date"

  export GRIMSHOT="$tmp/grimshot"
  export DATE="$tmp/date"
  export GRIMSHOT_LOG="$tmp/grimshot.log"
  script="$BATS_TEST_DIRNAME/../../.local/bin/sway-screenshot"
}

teardown() {
  rm -rf "$tmp"
}

@test "full saves and copies the focused output, not every monitor" {
  run "$script" full
  [ "$status" -eq 0 ]
  [ "$output" = "$XDG_PICTURES_DIR/Screenshots/screenshot-20260815-173000-123.png" ]
  [ -f "$output" ]
  readarray -t args <"$GRIMSHOT_LOG"
  [ "${args[0]}" = --notify ]
  [ "${args[1]}" = savecopy ]
  [ "${args[2]}" = output ]
  [ "${args[3]}" = "$output" ]
}

@test "area and window savecopy into Screenshots" {
  run "$script" area
  [ "$status" -eq 0 ]
  readarray -t args <"$GRIMSHOT_LOG"
  [ "${args[1]}" = savecopy ]
  [ "${args[2]}" = area ]

  run "$script" window
  [ "$status" -eq 0 ]
  readarray -t args <"$GRIMSHOT_LOG"
  [ "${args[2]}" = window ]
}

@test "unknown target exits 2" {
  run "$script" screen
  [ "$status" -eq 2 ]
}

@test "honors XDG_SCREENSHOTS_DIR" {
  export XDG_SCREENSHOTS_DIR="$tmp/custom"
  run "$script" full
  [ "$status" -eq 0 ]
  [ "$output" = "$tmp/custom/screenshot-20260815-173000-123.png" ]
}
