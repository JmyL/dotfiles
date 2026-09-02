#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  PATH="$tmp:$PATH"
  export HOME="$tmp/home"
  mkdir -p "$HOME"

  export WL_COPY="$tmp/wl-copy"
  export MAGICK="$tmp/magick"
  export FILE="$tmp/file"
  export WL_COPY_LOG="$tmp/wl-copy.log"
  export WL_COPY_PAYLOAD="$tmp/wl-copy.payload"
  export MAGICK_LOG="$tmp/magick.log"
  export FILE_LOG="$tmp/file.log"

  cat >"$WL_COPY" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"${WL_COPY_LOG:?}"
cat >"${WL_COPY_PAYLOAD:?}"
EOF
  chmod +x "$WL_COPY"

  cat >"$MAGICK" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"${MAGICK_LOG:?}"
printf 'FAKEPNG'
EOF
  chmod +x "$MAGICK"

  cat >"$FILE" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"${FILE_LOG:?}"
printf '%s\n' "${FILE_MIME:-image/jpeg}"
EOF
  chmod +x "$FILE"

  src="$tmp/photo.jpg"
  printf 'JPEGDATA' >"$src"
  png="$tmp/shot.png"
  printf 'PNGDATA' >"$png"

  script="$BATS_TEST_DIRNAME/../../.local/bin/wl-copy-image"
}

teardown() {
  rm -rf "$tmp"
}

@test "png is copied as-is without magick" {
  export FILE_MIME=image/png
  run "$script" "$png"
  [ "$status" -eq 0 ]
  [ "$output" = "shot.png yanked as PNG" ]
  [ "$(cat "$WL_COPY_LOG")" = "--type
image/png" ]
  [ "$(cat "$WL_COPY_PAYLOAD")" = "PNGDATA" ]
  [ ! -f "$MAGICK_LOG" ]
}

@test "jpeg is converted to png then copied" {
  export FILE_MIME=image/jpeg
  run "$script" "$src"
  [ "$status" -eq 0 ]
  [ "$output" = "photo.jpg yanked as PNG" ]
  [ "$(cat "$WL_COPY_LOG")" = "--type
image/png" ]
  [ "$(cat "$WL_COPY_PAYLOAD")" = "FAKEPNG" ]
  [ "$(cat "$MAGICK_LOG")" = "-quiet
$src
-delete
1--1
png:-" ]
}

@test "missing file exits 1" {
  run "$script" "$tmp/missing.png"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not a regular file"* ]]
}

@test "usage exits 2" {
  run "$script"
  [ "$status" -eq 2 ]
  [[ "$output" == Usage:* ]]
}

@test "non-png without magick exits 1" {
  export FILE_MIME=image/jpeg
  export MAGICK="$tmp/no-such-magick"
  run "$script" "$src"
  [ "$status" -eq 1 ]
  [[ "$output" == *"need ImageMagick"* ]]
}

@test "magick failure exits 1" {
  export FILE_MIME=image/jpeg
  cat >"$MAGICK" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
  chmod +x "$MAGICK"
  run "$script" "$src"
  [ "$status" -eq 1 ]
  [[ "$output" == *"cannot convert to PNG"* ]]
}
