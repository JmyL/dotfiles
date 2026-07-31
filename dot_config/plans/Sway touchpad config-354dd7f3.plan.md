<!-- 354dd7f3-0935-47eb-b3ee-cdb72819f935 -->
---
todos:
  - id: "add-touchpad-conf"
    content: "Create ~/.config/sway/config.d/05-touchpad.conf with tap + natural_scroll + tap_button_map lrm"
    status: pending
  - id: "reload-sway"
    content: "Reload sway and verify via swaymsg -t get_inputs"
    status: pending
  - id: "chezmoi-commit-push"
    content: "chezmoi add, commit, and push personal dotfiles"
    status: pending
isProject: false
---
# Sway touchpad 설정

## 현재 상태

- Touchpad: `SYNA8031:00 06CB:D007 Touchpad` (`type: touchpad`)
- `tap: disabled`, `natural_scroll: disabled`
- `tap_button_map`은 이미 `lrm` (1=좌클릭, 2=우클릭, 3=중클릭) — tap만 켜면 two-finger tap 우클릭이 됨
- 키보드 설정은 이미 [`~/.config/sway/config.d/05-keyboard.conf`](/home/sungsik/.config/sway/config.d/05-keyboard.conf)에 분리되어 있음
- [`~/.config/sway/config`](/home/sungsik/.config/sway/config)에는 touchpad 예시만 주석으로 있음

## 변경

새 파일 [`~/.config/sway/config.d/05-touchpad.conf`](/home/sungsik/.config/sway/config.d/05-touchpad.conf) 추가:

```sway
input type:touchpad {
    tap enabled
    natural_scroll enabled
    tap_button_map lrm
}
```

- `natural_scroll enabled` — 스크롤 방향 반전
- `tap enabled` — 탭으로 클릭
- `tap_button_map lrm` — two-finger tap = 우클릭 (기본값이지만 명시)

TrackPoint에는 적용하지 않음 (요청이 touchpad에 한정).

## 적용 / 관리

1. `swaymsg reload`로 즉시 반영
2. `chezmoi add ~/.config/sway/config.d/05-touchpad.conf`
3. personal chezmoi (`~/.local/share/chezmoi`)에 commit + push (`JmyL`)
