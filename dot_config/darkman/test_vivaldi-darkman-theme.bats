#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  export VIVALDI_DARKMAN_THEME_FILE="$tmp/vivaldi-darkman-theme"
  export GSETTINGS_BIN="$tmp/gsettings"
  export GSETTINGS_LOG="$tmp/gsettings.log"
  export GSETTINGS_FAIL=0
  export GTK3_SETTINGS_FILE="$tmp/gtk-3.0/settings.ini"
  export GTK4_SETTINGS_FILE="$tmp/gtk-4.0/settings.ini"
  export GSETTINGS_GTK_THEME="'Yaru-dark'"
  script="$BATS_TEST_DIRNAME/../../.local/bin/vivaldi-darkman-theme"
  host="$BATS_TEST_DIRNAME/../../.local/bin/vivaldi-darkman-host"

  cat >"$GSETTINGS_BIN" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${GSETTINGS_LOG:?}"
if [[ ${1:-} == get ]]; then
  printf '%s\n' "${GSETTINGS_GTK_THEME:-'Yaru-dark'}"
  exit 0
fi
exit "${GSETTINGS_FAIL:-0}"
EOF
  chmod +x "$GSETTINGS_BIN"
}

teardown() {
  rm -rf "$tmp"
}

@test "writes light into the state file and gsettings" {
  run "$script" light
  [ "$status" -eq 0 ]
  [ "$(cat "$VIVALDI_DARKMAN_THEME_FILE")" = "light" ]
  grep -F -- "set org.gnome.desktop.interface color-scheme prefer-light" "$GSETTINGS_LOG"
  grep -E -- 'set org.gnome.desktop.interface gtk-theme Yaru$' "$GSETTINGS_LOG"
}

@test "writes dark and prefers-dark" {
  run "$script" dark
  [ "$status" -eq 0 ]
  [ "$(cat "$VIVALDI_DARKMAN_THEME_FILE")" = "dark" ]
  grep -F -- "set org.gnome.desktop.interface color-scheme prefer-dark" "$GSETTINGS_LOG"
  grep -F -- "set org.gnome.desktop.interface gtk-theme Yaru-dark" "$GSETTINGS_LOG"
}

@test "writes GTK settings.ini for light and dark" {
  run "$script" light
  [ "$status" -eq 0 ]
  grep -F -- "gtk-theme-name=Adwaita" "$GTK3_SETTINGS_FILE"
  grep -F -- "gtk-application-prefer-dark-theme=0" "$GTK3_SETTINGS_FILE"
  grep -F -- "gtk-application-prefer-dark-theme=0" "$GTK4_SETTINGS_FILE"
  run "$script" dark
  [ "$status" -eq 0 ]
  grep -F -- "gtk-theme-name=Adwaita-dark" "$GTK3_SETTINGS_FILE"
  grep -F -- "gtk-application-prefer-dark-theme=1" "$GTK3_SETTINGS_FILE"
}

@test "gsettings failure does not undo a successful write" {
  export GSETTINGS_FAIL=1
  run "$script" light
  [ "$status" -eq 0 ]
  [ "$(cat "$VIVALDI_DARKMAN_THEME_FILE")" = "light" ]
  grep -F -- "gtk-application-prefer-dark-theme=0" "$GTK3_SETTINGS_FILE"
}

@test "skips gsettings when the binary is missing" {
  export GSETTINGS_BIN="$tmp/no-such-gsettings"
  run "$script" dark
  [ "$status" -eq 0 ]
  [ "$(cat "$VIVALDI_DARKMAN_THEME_FILE")" = "dark" ]
  [ ! -f "$GSETTINGS_LOG" ]
}

@test "rejects unknown themes" {
  run "$script" zen
  [ "$status" -eq 2 ]
  [ ! -f "$VIVALDI_DARKMAN_THEME_FILE" ]
  [ ! -f "$GTK3_SETTINGS_FILE" ]
}

@test "host --json-once prints the state file theme" {
  printf 'light\n' >"$VIVALDI_DARKMAN_THEME_FILE"
  run "$host" --json-once
  [ "$status" -eq 0 ]
  [ "$output" = '{"theme": "light"}' ]
}

@test "host --json-once fails when the state file is missing" {
  run "$host" --json-once
  [ "$status" -eq 1 ]
}
