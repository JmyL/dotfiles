#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  PATH="$tmp:$PATH"
  export HOME="$tmp/home"
  mkdir -p "$HOME/Pictures"
  export XDG_PICTURES_DIR="$HOME/Pictures"

  export SWAPPY="$tmp/swappy"
  export FOOT="$tmp/foot"
  export VIFM="$tmp/vifm"
  export SWAPPY_LOG="$tmp/swappy.log"
  export FOOT_LOG="$tmp/foot.log"
  export VIFM_LOG="$tmp/vifm.log"

  cat >"$SWAPPY" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"${SWAPPY_LOG:?}"
EOF
  chmod +x "$SWAPPY"

  cat >"$FOOT" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"${FOOT_LOG:?}"
while (($#)); do
  case "$1" in
  --app-id | --title | --window-size-chars)
    shift 2
    ;;
  --app-id=* | --title=* | --window-size-chars=*)
    shift
    ;;
  *)
    break
    ;;
  esac
done
exec "$@"
EOF
  chmod +x "$FOOT"

  cat >"$VIFM" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"${VIFM_LOG:?}"
outfile=
while (($#)); do
  case "$1" in
  --choose-files)
    outfile=$2
    shift 2
    ;;
  -c)
    shift 2
    ;;
  *)
    shift
    ;;
  esac
done
if [[ -n ${VIFM_OUT:-} && -n $outfile ]]; then
  printf '%s\n' "$VIFM_OUT" >"$outfile"
  exit 0
fi
exit 1
EOF
  chmod +x "$VIFM"

  src="$tmp/photo.png"
  printf 'PNG' >"$src"

  script="$BATS_TEST_DIRNAME/../../.local/bin/swappy-open"
}

teardown() {
  rm -rf "$tmp"
}

@test "opens a given file without vifm" {
  run "$script" "$src"
  [ "$status" -eq 0 ]
  [ "$(cat "$SWAPPY_LOG")" = "-f
$src" ]
  [ ! -f "$FOOT_LOG" ]
  [ ! -f "$VIFM_LOG" ]
}

@test "no args picks a file in floating vifm then opens it" {
  export VIFM_OUT=$src
  run "$script"
  [ "$status" -eq 0 ]
  [ "$(cat "$SWAPPY_LOG")" = "-f
$src" ]
  grep -Fx -- "--app-id=swappy-open" "$FOOT_LOG"
  grep -Fx -- "--choose-files" "$VIFM_LOG"
  grep -Fx -- "$XDG_PICTURES_DIR" "$VIFM_LOG"
}

@test "canceling vifm exits 0" {
  unset VIFM_OUT
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
