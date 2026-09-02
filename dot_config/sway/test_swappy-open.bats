#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  PATH="$tmp:$PATH"
  export HOME="$tmp/home"
  mkdir -p "$HOME/Pictures"
  export XDG_PICTURES_DIR="$HOME/Pictures"

  export SWAPPY="$tmp/swappy"
  export ZENITY="$tmp/zenity"
  export SWAPPY_LOG="$tmp/swappy.log"
  export ZENITY_LOG="$tmp/zenity.log"

  cat >"$SWAPPY" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"${SWAPPY_LOG:?}"
EOF
  chmod +x "$SWAPPY"

  cat >"$ZENITY" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"${ZENITY_LOG:?}"
if [[ -n "${ZENITY_OUT:-}" ]]; then
  printf '%s\n' "$ZENITY_OUT"
  exit 0
fi
exit 1
EOF
  chmod +x "$ZENITY"

  src="$tmp/photo.png"
  printf 'PNG' >"$src"

  script="$BATS_TEST_DIRNAME/../../.local/bin/swappy-open"
}

teardown() {
  rm -rf "$tmp"
}

@test "opens a given file without zenity" {
  run "$script" "$src"
  [ "$status" -eq 0 ]
  [ "$(cat "$SWAPPY_LOG")" = "-f
$src" ]
  [ ! -f "$ZENITY_LOG" ]
}

@test "no args picks a file then opens it" {
  export ZENITY_OUT=$src
  run "$script"
  [ "$status" -eq 0 ]
  [ "$(cat "$SWAPPY_LOG")" = "-f
$src" ]
  grep -F -- "--file-selection" "$ZENITY_LOG"
  grep -F -- "--filename=${XDG_PICTURES_DIR}/" "$ZENITY_LOG"
}

@test "canceling the picker exits 0" {
  unset ZENITY_OUT
  run "$script"
  [ "$status" -eq 0 ]
  [ ! -f "$SWAPPY_LOG" ]
}

@test "missing file exits 1" {
  run "$script" "$tmp/missing.png"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not a regular file"* ]]
}

@test "usage exits 2" {
  run "$script" --help
  [ "$status" -eq 2 ]
  [[ "$output" == Usage:* ]]
}
