<!-- d7a12297-c8ce-4568-bc15-9d5bef7bdcc1 -->
---
todos:
  - id: "edit-swaync-conf"
    content: "20-swaync.conf를 exec_always + pkill -x swaync 패턴으로 수정"
    status: pending
  - id: "reload-verify"
    content: "sway reload 후 swaync/notify-send 확인, stuck swaync-client 정리"
    status: pending
  - id: "chezmoi-commit"
    content: "chezmoi add → diff → personal repo commit/push"
    status: pending
isProject: false
---
# swaync reload 복구 (exec_always)

## 결정

[`~/.config/sway/config.d/20-swaync.conf`](/home/sungsik/.config/sway/config.d/20-swaync.conf)를 kanshi와 같은 패턴으로 바꾼다. [`swaync.service` mask](/home/sungsik/.config/systemd/user/swaync.service)는 그대로 둔다 — `graphical-session.target`이 systemd로 또 띄우는 걸 막는 용도.

```mermaid
flowchart LR
  reload[sway reload]
  pkill[pkill -x swaync]
  start[exec swaync]
  dbus[org.freedesktop.Notifications]
  reload --> pkill --> start --> dbus
```

## 변경

[`20-swaync.conf`](/home/sungsik/.config/sway/config.d/20-swaync.conf):

```conf
# Notification daemon and notification center.
# Restart on Sway reload so a dead daemon comes back (systemd unit stays masked).
exec_always sh -c 'command -v swaync >/dev/null 2>&1 || exit 0; pkill -x swaync 2>/dev/null || true; exec swaync'
```

참고 패턴: [`20-kanshi.conf`](/home/sungsik/.config/sway/config.d/20-kanshi.conf)의 `exec_always` + `pkill -x` + `exec`.

## 적용·검증

1. live 파일 수정 후 `swaymsg reload` (또는 지금 데몬이 없으면 reload만으로도 기동됨).
2. `pgrep -a '^swaync$'`, `notify-send 'swaync test' 'hello'`로 확인.
3. 남아 있는 좀비 `swaync-client`는 `pkill swaync-client`로 정리.
4. `chezmoi add ~/.config/sway/config.d/20-swaync.conf` → diff → personal chezmoi commit/push (`JmyL`).

## 범위 밖

- `herdr-focus-notify`의 Cursor `idle` 상태 알림 (별도 이슈)
- `swaync.service` unmask / systemd 전환
- blueman·swayosd 등 다른 `exec` 데몬들