#!/usr/bin/env bats

script="$BATS_TEST_DIRNAME/../../.local/bin/reeplay-open-firefox"

setup() {
  tmp=$(mktemp -d)
  PATH="$tmp:$PATH"
  export FIREFOX="$tmp/firefox"
  export SWAYMSG="$tmp/swaymsg"
  export FIREFOX_APP_ID=firefox_firefox
  export URGENT_POLL_COUNT=1
  export URGENT_POLL_INTERVAL=0
  export FIREFOX_LOG="$tmp/firefox.log"
  export SWAYMSG_LOG="$tmp/swaymsg.log"

  cat >"$tmp/firefox" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >>"${FIREFOX_LOG:?}"
EOF
  chmod +x "$tmp/firefox"

  cat >"$tmp/swaymsg" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${SWAYMSG_LOG:?}"
exit 0
EOF
  chmod +x "$tmp/swaymsg"

  : >"$FIREFOX_LOG"
  : >"$SWAYMSG_LOG"
}

teardown() {
  rm -rf "$tmp"
}

@test "CLI opens a reeplay URL in Firefox and focuses it" {
  run "$script" 'https://reeplay.reeinfra.net/index-v2.html?x=1'
  [ "$status" -eq 0 ]
  [ "$(sed -n '1p' "$SWAYMSG_LOG")" = "exec $tmp/firefox https://reeplay.reeinfra.net/index-v2.html\\?x=1" ]
  [ "$(sed -n '2p' "$SWAYMSG_LOG")" = '[app_id="firefox_firefox" urgent=latest] focus' ]
}

@test "CLI rejects a lookalike host" {
  run "$script" 'https://reeplay.reeinfra.net.evil.com/'
  [ "$status" -ne 0 ]
  [ ! -s "$SWAYMSG_LOG" ]
}

@test "native host rejects an empty stdin payload" {
  run "$script" </dev/null
  [ "$status" -ne 0 ]
}

@test "native host opens a valid URL and replies ok" {
  reply=$tmp/reply
  python3 -c 'import json,struct,sys; data=json.dumps({"url":"https://reeplay.reeinfra.net/"}).encode(); sys.stdout.buffer.write(struct.pack("<I", len(data))+data)' | "$script" >"$reply"
  [ "$(sed -n '1p' "$SWAYMSG_LOG")" = "exec $tmp/firefox https://reeplay.reeinfra.net/" ]
  [ "$(python3 -c 'import json,struct,sys; n=struct.unpack("<I", sys.stdin.buffer.read(4))[0]; print(json.loads(sys.stdin.buffer.read(n))["ok"])' <"$reply")" = "True" ]
}

@test "native host rejects a non-reeplay URL" {
  reply=$tmp/reply
  set +e
  python3 -c 'import json,struct,sys; data=json.dumps({"url":"https://example.com/"}).encode(); sys.stdout.buffer.write(struct.pack("<I", len(data))+data)' | "$script" >"$reply"
  status=$?
  set -e
  [ "$status" -ne 0 ]
  [ "$(python3 -c 'import json,struct,sys; n=struct.unpack("<I", sys.stdin.buffer.read(4))[0]; print(json.loads(sys.stdin.buffer.read(n))["ok"])' <"$reply")" = "False" ]
  [ ! -s "$SWAYMSG_LOG" ]
}
