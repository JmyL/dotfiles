#!/usr/bin/env bats

script="$BATS_TEST_DIRNAME/../../.local/bin/sway-place-showmethekey"

@test "bottom-centers an 800x100 overlay on 2560x1440" {
  run "$script" --compute 0 0 2560 1440 800 100 24
  [ "$status" -eq 0 ]
  [ "$output" = "880 1316" ]
}

@test "keeps the output origin on a second monitor" {
  run "$script" --compute 2560 0 1920 1080 800 100 24
  [ "$status" -eq 0 ]
  [ "$output" = "3120 956" ]
}

@test "compute requires all seven numbers" {
  run "$script" --compute 0 0 2560
  [ "$status" -ne 0 ]
}
