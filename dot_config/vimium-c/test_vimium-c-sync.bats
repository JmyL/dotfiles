#!/usr/bin/env bats

script="$BATS_TEST_DIRNAME/../../.local/bin/vimium-c-sync"

setup() {
  tmp=$(mktemp -d)
  export VIMIUM_C_DIR="$tmp/vimium-c"
  export VIMIUM_C_TRACKED="$tmp/vimium-c/settings.json"
  export VIMIUM_C_DOWNLOADS="$tmp/Downloads"
  export CHEZMOI="$tmp/chezmoi"
  export VIMIUM_C_CDP_PY="$BATS_TEST_DIRNAME/cdp.py"
  export VIMIUM_C_CDP_PORT=1
  export VIMIUM_C_CDP_TIMEOUT=0.05
  export VIMIUM_C_START_VIVALDI=0
  export VIMIUM_C_VIVALDI_RUNNING=0
  unset VIMIUM_C_CDP_DUMP VIMIUM_C_CDP_APPLY VIMIUM_C_CDP_PROBE
  export VIMIUM_C_EXTRACTED="$tmp/extracted.json"
  export VIMIUM_C_OPEN="$tmp/open"
  export VIMIUM_C_MERGETOOL="$tmp/mergetool"
  export CHEZMOI_LOG="$tmp/chezmoi.log"
  export OPEN_LOG="$tmp/open.log"
  export MERGE_LOG="$tmp/merge.log"
  mkdir -p "$VIMIUM_C_DOWNLOADS"

  cat >"$CHEZMOI" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${CHEZMOI_LOG:?}"
EOF
  chmod +x "$CHEZMOI"

  cat >"$VIMIUM_C_OPEN" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${OPEN_LOG:?}"
EOF
  chmod +x "$VIMIUM_C_OPEN"

  cat >"$VIMIUM_C_MERGETOOL" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${MERGE_LOG:?}"
# Copy incoming (first arg) over ours (second arg).
cp "$1" "$2"
EOF
  chmod +x "$VIMIUM_C_MERGETOOL"
}

teardown() {
  rm -rf "$tmp"
}

write_export() {
  local dest=$1
  local mappings=${2:-$'map <a-p> visitPreviousTab\nmap <a-a> togglePinTab'}
  mkdir -p "$(dirname -- "$dest")"
  python3 - "$dest" "$mappings" <<'PY'
import json, sys
path, mappings = sys.argv[1], sys.argv[2]
data = {
    "name": "Vimium C",
    "@time": "9/7/2026, 10:00:00 AM",
    "time": 1757232000000,
    "environment": {
        "extension": "2.12.2",
        "platform": "linux",
        "chromium": 150,
    },
    "keyMappings": mappings.split("\n") + [""],
}
with open(path, "w", encoding="utf-8") as out:
    json.dump(data, out, indent="\t")
    out.write("\n")
PY
}

@test "usage with no args" {
  run "$script"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: vimium-c-sync"* ]]
}

@test "incoming fails when no export exists and auto-start is off" {
  run "$script" incoming
  [ "$status" -eq 2 ]
  [[ "$output" == *"auto-start disabled"* ]]
}

@test "extract starts Vivaldi when CDP is down" {
  write_export "$tmp/later-dump.json"
  export VIVALDI_LOG="$tmp/vivaldi.log"
  cat >"$tmp/vivaldi" <<EOF
#!/usr/bin/env bash
printf 'started\n' >>"${VIVALDI_LOG}"
cp "$tmp/later-dump.json" "$tmp/dump.json"
touch "$tmp/cdp-up"
EOF
  chmod +x "$tmp/vivaldi"
  cat >"$tmp/probe" <<EOF
#!/usr/bin/env bash
[[ -f "$tmp/cdp-up" ]]
EOF
  chmod +x "$tmp/probe"
  export VIMIUM_C_START_VIVALDI=1
  export VIMIUM_C_VIVALDI="$tmp/vivaldi"
  export VIMIUM_C_CDP_PROBE="$tmp/probe"
  export VIMIUM_C_CDP_WAIT=1
  export VIMIUM_C_CDP_SLEEP=0.05
  export VIMIUM_C_CDP_DUMP="$tmp/dump.json"
  run "$script" extract "$tmp/out.json"
  [ "$status" -eq 0 ]
  grep -F -- started "$VIVALDI_LOG"
  grep -F -- '"Vimium C"' "$tmp/out.json"
}

@test "does not start Vivaldi when it is already running without CDP" {
  cat >"$tmp/vivaldi" <<'EOF'
#!/usr/bin/env bash
printf 'started\n' >>"${VIVALDI_LOG:?}"
EOF
  chmod +x "$tmp/vivaldi"
  export VIMIUM_C_START_VIVALDI=1
  export VIMIUM_C_VIVALDI_RUNNING=1
  export VIMIUM_C_VIVALDI="$tmp/vivaldi"
  export VIVALDI_LOG="$tmp/vivaldi.log"
  run "$script" extract "$tmp/out.json"
  [ "$status" -eq 2 ]
  [[ "$output" == *"running without CDP"* ]]
  [ ! -f "$VIVALDI_LOG" ]
}

@test "incoming uses a CDP dump when Downloads is empty" {
  write_export "$tmp/dump.json"
  write_export "$VIMIUM_C_TRACKED" $'map <a-p> visitPreviousTab\nmap <a-a> togglePinTab'
  export VIMIUM_C_CDP_DUMP="$tmp/dump.json"
  run "$script" incoming
  [ "$status" -eq 0 ]
  [[ "$output" == *"no settings differences"* ]]
}

@test "extract writes a dump to the given file" {
  write_export "$tmp/dump.json"
  export VIMIUM_C_CDP_DUMP="$tmp/dump.json"
  run "$script" extract "$tmp/out.json"
  [ "$status" -eq 0 ]
  [[ -f "$tmp/out.json" ]]
  grep -F -- '"Vimium C"' "$tmp/out.json"
}

@test "apply writes storage keys to VIMIUM_C_CDP_APPLY" {
  write_export "$VIMIUM_C_TRACKED"
  export VIMIUM_C_CDP_APPLY="$tmp/applied.json"
  run "$script" apply
  [ "$status" -eq 0 ]
  python3 - "$tmp/applied.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert "name" not in data
assert "keyMappings" in data
assert "\n" in data["keyMappings"]
PY
}

@test "incoming rejects a non-Vimium JSON" {
  printf '{ "name": "other" }\n' >"$tmp/other.json"
  run "$script" incoming "$tmp/other.json"
  [ "$status" -eq 2 ]
  [[ "$output" == *"not a Vimium C Export"* ]]
}

@test "incoming with no tracked file reports that adopt is needed" {
  write_export "$VIMIUM_C_DOWNLOADS/vimium_c-20260907_100000.json"
  run "$script" incoming
  [ "$status" -eq 1 ]
  [[ "$output" == *"no tracked settings yet"* ]]
}

@test "incoming ignores export time and chromium version" {
  write_export "$tmp/a.json"
  run "$script" adopt --no-chezmoi "$tmp/a.json"
  [ "$status" -eq 0 ]
  python3 - "$tmp/a.json" "$tmp/b.json" <<'PY'
import json, sys
data = json.loads(open(sys.argv[1], encoding="utf-8").read())
data["@time"] = "later"
data["time"] = 999
data["environment"]["chromium"] = 151
json.dump(data, open(sys.argv[2], "w", encoding="utf-8"), indent=2)
PY
  run "$script" incoming "$tmp/b.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no settings differences"* ]]
}

@test "incoming diffs keyMappings" {
  write_export "$tmp/a.json"
  "$script" --no-chezmoi adopt "$tmp/a.json"
  write_export "$tmp/b.json" $'map <a-p> visitPreviousTab'
  run "$script" incoming "$tmp/b.json"
  [ "$status" -eq 1 ]
  [[ "$output" == *"keyMappings"* ]]
}

@test "adopt writes a normalized tracked file and chezmoi add" {
  write_export "$VIMIUM_C_DOWNLOADS/vimium_c-settings.json"
  run "$script" adopt
  [ "$status" -eq 0 ]
  [[ "$output" == *"chezmoi add"* ]]
  grep -F -- "add $VIMIUM_C_TRACKED" "$CHEZMOI_LOG"
  python3 - "$VIMIUM_C_TRACKED" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["name"] == "Vimium C"
assert "time" not in data
assert "@time" not in data
assert "chromium" not in data["environment"]
assert data["environment"]["platform"] == "linux"
assert data["keyMappings"][0].startswith("map")
PY
}

@test "adopt --no-chezmoi skips chezmoi" {
  write_export "$tmp/a.json"
  run "$script" adopt --no-chezmoi "$tmp/a.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"chezmoi add skipped"* ]]
  [ ! -f "$CHEZMOI_LOG" ]
}

@test "merge writes mergetool result and chezmoi add" {
  write_export "$tmp/old.json" $'map <a-p> visitPreviousTab'
  write_export "$tmp/new.json" $'map <a-a> togglePinTab'
  "$script" --no-chezmoi adopt "$tmp/old.json"
  run "$script" merge "$tmp/new.json"
  [ "$status" -eq 0 ]
  grep -F -- "togglePinTab" "$VIMIUM_C_TRACKED"
  grep -F -- "add $VIMIUM_C_TRACKED" "$CHEZMOI_LOG"
}

@test "import --open prints the path and opens Options" {
  write_export "$tmp/a.json"
  "$script" --no-chezmoi adopt "$tmp/a.json"
  run "$script" import --open
  [ "$status" -eq 0 ]
  [[ "$output" == *"$VIMIUM_C_TRACKED"* ]]
  grep -F -- "chrome-extension://hfjbmagddngcpeloejdejnfgbamkjaeg/pages/options.html" "$OPEN_LOG"
}

@test "path prints the tracked file" {
  run "$script" path
  [ "$status" -eq 0 ]
  [ "$output" = "$VIMIUM_C_TRACKED" ]
}

@test "unknown command exits 2" {
  run "$script" frobnicate
  [ "$status" -eq 2 ]
}
