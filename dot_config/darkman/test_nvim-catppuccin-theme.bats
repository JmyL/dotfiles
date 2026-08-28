#!/usr/bin/env bats

setup() {
  tmp=$(mktemp -d)
  export XDG_RUNTIME_DIR="$tmp/run"
  mkdir -p "$XDG_RUNTIME_DIR"
  export NVIM_BIN="$tmp/nvim"
  export NVIM_LOG="$tmp/nvim.log"
  script="$BATS_TEST_DIRNAME/../../.local/bin/nvim-catppuccin-theme"

  cat >"$NVIM_BIN" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${NVIM_LOG:?}"
EOF
  chmod +x "$NVIM_BIN"
}

teardown() {
  rm -rf "$tmp"
}

bind_socket() {
  python3 -c 'import socket,sys; s=socket.socket(socket.AF_UNIX); s.bind(sys.argv[1])' "$1"
}

@test "exits 0 when no nvim sockets exist" {
  run "$script" latte
  [ "$status" -eq 0 ]
  [ ! -f "$NVIM_LOG" ]
}

@test "sends latte colorscheme to each nvim socket" {
  bind_socket "$XDG_RUNTIME_DIR/nvim.111.0"
  bind_socket "$XDG_RUNTIME_DIR/nvim.222.0"
  run "$script" latte
  [ "$status" -eq 0 ]
  grep -F -- "--server $XDG_RUNTIME_DIR/nvim.111.0 --remote-send <Cmd>set background=light | colorscheme catppuccin-latte<CR>" "$NVIM_LOG"
  grep -F -- "--server $XDG_RUNTIME_DIR/nvim.222.0 --remote-send <Cmd>set background=light | colorscheme catppuccin-latte<CR>" "$NVIM_LOG"
  ! grep -F -- "catppuccin-macchiato" "$NVIM_LOG"
}

@test "sends macchiato colorscheme" {
  bind_socket "$XDG_RUNTIME_DIR/nvim.111.0"
  run "$script" macchiato
  [ "$status" -eq 0 ]
  grep -F -- "--server $XDG_RUNTIME_DIR/nvim.111.0 --remote-send <Cmd>set background=dark | colorscheme catppuccin-macchiato<CR>" "$NVIM_LOG"
}

@test "rejects unknown flavors" {
  run "$script" mocha
  [ "$status" -eq 2 ]
  [ ! -f "$NVIM_LOG" ]
}
