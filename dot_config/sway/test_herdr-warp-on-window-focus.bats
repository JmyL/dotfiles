#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  export HOME="$tmp/home"
  export XDG_CONFIG_HOME="$HOME/.config"
  mkdir -p "$XDG_CONFIG_HOME/herdr/plugins/fake"
  script="$BATS_TEST_DIRNAME/../../.local/bin/herdr-warp-on-window-focus"
  plugin_script="$XDG_CONFIG_HOME/herdr/plugins/fake/herdr-warp-on-window-focus"
  log="$tmp/plugin.log"

  cat >"$plugin_script" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >"$log"
EOF
  chmod +x "$plugin_script"

  python3 - "$XDG_CONFIG_HOME/herdr/plugins.json" "$XDG_CONFIG_HOME/herdr/plugins/fake" <<'PY'
import json
import sys
from pathlib import Path

Path(sys.argv[1]).write_text(
    json.dumps(
        [
            {
                "plugin_id": "herdr-pane-mouse-warp",
                "enabled": True,
                "plugin_root": sys.argv[2],
            }
        ]
    )
    + "\n",
    encoding="utf-8",
)
PY
}

teardown() {
  rm -rf "$tmp"
}

@test "execs the plugin window-focus script with the same args" {
  run "$script" --pid 123 --title "herdr: dotfiles"
  [ "$status" -eq 0 ]
  [ "$(cat "$log")" = "--pid 123 --title herdr: dotfiles" ]
}

@test "exits quietly when the plugin is missing" {
  printf '%s\n' '[]' >"$XDG_CONFIG_HOME/herdr/plugins.json"
  run "$script" --pid 123
  [ "$status" -eq 0 ]
  [ ! -f "$log" ]
}
