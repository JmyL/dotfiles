#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  export HOME="$tmp/home"
  mkdir -p "$HOME" \
    "$tmp/bin" \
    "$tmp/wallpapers/light" \
    "$tmp/wallpapers/dark" \
    "$tmp/runtime"
  export XDG_RUNTIME_DIR="$tmp/runtime"
  export SWAY_WALLPAPER_ROOT="$tmp/wallpapers"
  export SWAY_WALLPAPER_CACHE_ROOT="$tmp/cache"
  export SWAY_CURRENT_WALLPAPER="$tmp/wallpaper-current"
  export SWAY_WALLPAPER_SLEEP=1

  printf '%s\n' '#!/bin/sh' 'echo "$@"' >"$tmp/bin/swaymsg"
  printf '%s\n' '#!/bin/sh' 'echo light' >"$tmp/bin/darkman"
  chmod +x "$tmp/bin/swaymsg" "$tmp/bin/darkman"
  export SWAYMSG="$tmp/bin/swaymsg"
  export DARKMAN="$tmp/bin/darkman"
  export PATH="$tmp/bin:$PATH"

  script="$BATS_TEST_DIRNAME/sway-theme-wallpaper"
}

teardown() {
  if [ -n "${watcher_pid:-}" ]; then
    kill "$watcher_pid" 2>/dev/null || true
    wait "$watcher_pid" 2>/dev/null || true
  fi
  rm -rf "$tmp"
}

@test "--once light links the wallpaper and calls swaymsg" {
  printf 'img\n' >"$tmp/wallpapers/light/light-good-will-hunting.jpg"
  run "$script" --once light
  [ "$status" -eq 0 ]
  [ -L "$SWAY_CURRENT_WALLPAPER" ]
  [ "$(readlink "$SWAY_CURRENT_WALLPAPER")" = "$tmp/wallpapers/light/light-good-will-hunting.jpg" ]
}

@test "--once does nothing when the mode directory is empty" {
  run "$script" --once light
  [ "$status" -eq 0 ]
  [ ! -e "$SWAY_CURRENT_WALLPAPER" ]
}

@test "watcher retries after wallpapers appear" {
  "$script" &
  watcher_pid=$!
  sleep 0.4
  [ ! -e "$SWAY_CURRENT_WALLPAPER" ]

  printf 'img\n' >"$tmp/wallpapers/light/light-good-will-hunting.jpg"
  sleep 1.4
  [ -L "$SWAY_CURRENT_WALLPAPER" ]
}
