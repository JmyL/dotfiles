#!/usr/bin/env bats

setup() {
  bashrc="$BATS_TEST_DIRNAME/../../.bashrc.d/herdr-color"
}

@test "unsets NO_COLOR inside a herdr pane" {
  run bash -c '
    export HERDR_ENV=1 NO_COLOR=1 FORCE_COLOR=0
    # shellcheck disable=SC1090
    source "$1"
    [[ -z ${NO_COLOR+x} ]]
    [[ -z ${FORCE_COLOR+x} ]]
  ' _ "$bashrc"
  [ "$status" -eq 0 ]
}

@test "leaves NO_COLOR alone outside herdr" {
  run bash -c '
    unset HERDR_ENV
    export NO_COLOR=1 FORCE_COLOR=0
    # shellcheck disable=SC1090
    source "$1"
    [[ $NO_COLOR == 1 ]]
    [[ $FORCE_COLOR == 0 ]]
  ' _ "$bashrc"
  [ "$status" -eq 0 ]
}

@test "herdr wrapper strips NO_COLOR from the child" {
  tmp=$(mktemp -d)
  cat >"$tmp/herdr" <<'EOF'
#!/usr/bin/env bash
printf 'NO_COLOR=%s FORCE_COLOR=%s\n' "${NO_COLOR-<unset>}" "${FORCE_COLOR-<unset>}"
EOF
  chmod +x "$tmp/herdr"
  run bash -c '
    # shellcheck disable=SC1090
    source "$1"
    export NO_COLOR=1 FORCE_COLOR=0 PATH="$2:$PATH"
    herdr status
  ' _ "$bashrc" "$tmp"
  rm -rf "$tmp"
  [ "$status" -eq 0 ]
  [ "$output" = "NO_COLOR=<unset> FORCE_COLOR=<unset>" ]
}
