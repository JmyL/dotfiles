#!/usr/bin/env bats

script="$BATS_TEST_DIRNAME/../../.local/bin/xdg-open"

setup() {
  tmp=$(mktemp -d)
  PATH="$tmp:$PATH"
  export XDG_OPEN="$tmp/real-xdg-open"
  export SWAYMSG="$tmp/swaymsg"
  export URGENT_POLL_COUNT=1
  export URGENT_POLL_INTERVAL=0
  export BROWSER_APP_ID=vivaldi-stable
  export FIREFOX="$tmp/firefox"
  export FIREFOX_APP_ID=firefox_firefox
  export XDG_OPEN_LOG="$tmp/xdg-open.log"
  export FIREFOX_LOG="$tmp/firefox.log"
  export SWAYMSG_LOG="$tmp/swaymsg.log"

  cat >"$tmp/real-xdg-open" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >>"${XDG_OPEN_LOG:?}"
EOF
  chmod +x "$tmp/real-xdg-open"

  cat >"$tmp/firefox" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >>"${FIREFOX_LOG:?}"
EOF
  chmod +x "$tmp/firefox"

  cat >"$tmp/swaymsg" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${SWAYMSG_LOG:?}"
case "$*" in
*"urgent=latest"*)
  if [[ "${URGENT_FAIL:-0}" == 1 ]]; then
    exit 1
  fi
  ;;
esac
exit 0
EOF
  chmod +x "$tmp/swaymsg"

  : >"$XDG_OPEN_LOG"
  : >"$SWAYMSG_LOG"
}

teardown() {
  rm -rf "$tmp"
}

@test "http URLs exec through Sway and focus the urgent Vivaldi window" {
  run "$script" 'https://example.com/page'
  [ "$status" -eq 0 ]
  [ ! -s "$XDG_OPEN_LOG" ]
  [ "$(sed -n '1p' "$SWAYMSG_LOG")" = "exec $tmp/real-xdg-open https://example.com/page" ]
  [ "$(sed -n '2p' "$SWAYMSG_LOG")" = '[app_id="vivaldi-stable" urgent=latest] focus' ]
}

@test "local HTML files exec through Sway with an absolute path" {
  html="$tmp/page.html"
  : >"$html"
  cd "$tmp"
  run "$script" page.html
  [ "$status" -eq 0 ]
  [ ! -s "$XDG_OPEN_LOG" ]
  [ "$(sed -n '1p' "$SWAYMSG_LOG")" = "exec $tmp/real-xdg-open $html" ]
  [ "$(sed -n '2p' "$SWAYMSG_LOG")" = '[app_id="vivaldi-stable" urgent=latest] focus' ]
}

@test "file:// HTML URLs exec through Sway" {
  run "$script" 'file:///tmp/report.html'
  [ "$status" -eq 0 ]
  [ "$(sed -n '1p' "$SWAYMSG_LOG")" = "exec $tmp/real-xdg-open file:///tmp/report.html" ]
}

@test "falls back to any Vivaldi window when none is urgent" {
  export URGENT_FAIL=1
  run "$script" 'https://example.com/'
  [ "$status" -eq 0 ]
  [ "$(sed -n '2p' "$SWAYMSG_LOG")" = '[app_id="vivaldi-stable" urgent=latest] focus' ]
  [ "$(sed -n '3p' "$SWAYMSG_LOG")" = '[app_id="vivaldi-stable"] focus' ]
}

@test "non-HTML files pass through to the real xdg-open" {
  run "$script" "$tmp/notes.txt"
  [ "$status" -eq 0 ]
  [ "$(cat "$XDG_OPEN_LOG")" = "$tmp/notes.txt" ]
  [ ! -s "$SWAYMSG_LOG" ]
}

@test "missing swaymsg passes browser targets through" {
  export SWAYMSG=missing-swaymsg
  run "$script" 'https://example.com/'
  [ "$status" -eq 0 ]
  [ "$(cat "$XDG_OPEN_LOG")" = "https://example.com/" ]
  [ ! -s "$SWAYMSG_LOG" ]
}

@test "reeplay URLs exec Firefox and focus the Firefox window" {
  run "$script" 'https://reeplay.reeinfra.net/index-v2.html?session_id=abc'
  [ "$status" -eq 0 ]
  [ ! -s "$XDG_OPEN_LOG" ]
  [ "$(sed -n '1p' "$SWAYMSG_LOG")" = "exec $tmp/firefox https://reeplay.reeinfra.net/index-v2.html\\?session_id=abc" ]
  [ "$(sed -n '2p' "$SWAYMSG_LOG")" = '[app_id="firefox_firefox" urgent=latest] focus' ]
}

@test "reeplay lookalike hosts stay on the default browser" {
  run "$script" 'https://reeplay.reeinfra.net.evil.com/'
  [ "$status" -eq 0 ]
  [ "$(sed -n '1p' "$SWAYMSG_LOG")" = "exec $tmp/real-xdg-open https://reeplay.reeinfra.net.evil.com/" ]
  [ "$(sed -n '2p' "$SWAYMSG_LOG")" = '[app_id="vivaldi-stable" urgent=latest] focus' ]
}

@test "missing swaymsg opens reeplay URLs in Firefox" {
  export SWAYMSG=missing-swaymsg
  run "$script" 'https://reeplay.reeinfra.net/'
  [ "$status" -eq 0 ]
  [ "$(cat "$FIREFOX_LOG")" = "https://reeplay.reeinfra.net/" ]
  [ ! -s "$XDG_OPEN_LOG" ]
  [ ! -s "$SWAYMSG_LOG" ]
}
