<!-- b494c02c-0496-46d4-9068-fcbfe50b8f13 -->
---
todos:
  - id: "verify-session"
    content: "Sway restart/login path: exec-only swaync, D-Bus owner, notify-send + keybinds smoke test"
    status: pending
  - id: "enrich-config"
    content: "Add widgets/widget-config to ~/.config/swaync/config.json; reload; chezmoi add/commit/push"
    status: cancelled
  - id: "tool-inventory"
    content: "Add sway-notification-center / SwayNotificationCenter to tool-inventory install lists; chezmoi commit/push"
    status: pending
isProject: false
---
# swaync 사용을 위한 추가 스텝

## 현재 상태 (이미 됨)

- `mako-notifier` purge, user `mako.service` mask ([`symlink_mako.service`](/home/sungsik/.local/share/chezmoi/dot_config/systemd/user/symlink_mako.service))
- Notifications 버스 소유: `swaync`
- Sway 기동: [`20-swaync.conf`](/home/sungsik/.config/sway/config.d/20-swaync.conf) `exec ... swaync`
- 키바인딩: `$mod+n` 토글, `$mod+Shift+n` clear, `$mod+Return` 최신 액션 (터미널은 `$mod+i`)
- User 설정: [`~/.config/swaync/config.json`](/home/sungsik/.config/swaync/config.json) + [`style.css`](/home/sungsik/.config/swaync/style.css) — chezmoi에 이미 있는 **이전 swaync config**와 동일 (`329c9d7` / pre-mako). 새로 만들지 않음.
- `swaync.service`는 **계속 mask** (이중 기동 방지) — 바꾸지 않음

## 결정

`config.json`/`style.css` 보강(시스템 기본 widgets 병합)은 **하지 않는다**. 기존 overlay(소리 스크립트 + Catppuccin style)로 충분하고, widget-config 경고는 기본값 fallback이라 무시.

## 남은 작업

### 1. 세션 기동 검증

- 수동으로 띄운 `swaync`를 끄고, sway 재로그인(또는 sway 재시작) 후 `exec` 경로로만 기동되는지 확인.
- `busctl --user status org.freedesktop.Notifications` → `Comm=swaync`
- `notify-send "swaync test" "hello"` + 소리 확인.
- 키바인딩 3개 스모크 테스트.

### 2. tool-inventory 정리

[`~/.config/tool-inventory.md`](/home/sungsik/.config/tool-inventory.md):

- Notifications 목록에 `sway-notification-center` (provides `swaync` / `swaync-client`) 명시
- Fedora install 줄에 `SwayNotificationCenter`, Ubuntu install 줄에 `sway-notification-center` 추가
- “may need separate”의 `swaync-client`는 install 명령에 넣은 뒤 정리
- `mako` / `mako-notifier`는 추가하지 않음

chezmoi add → commit/push.

## 하지 않을 것

- swaync `config.json` / `style.css` 신규 작성·widgets 보강 (기존 config 유지)
- `swaync.service` unmask / systemd로 전환
- waybar custom 모듈
- mako 시절 키맵 복원
