<!-- ceb25705-8ed9-4eac-9ccb-5427b182b0f1 -->
---
todos:
  - id: "create-dropin"
    content: "Create /etc/systemd/logind.conf.d/lid-always-suspend.conf and reload systemd-logind"
    status: pending
  - id: "verify"
    content: "Confirm all three HandleLidSwitch* properties are suspend"
    status: pending
isProject: false
---
# Lid close always suspend

## Why
Sway는 뚜껑 이벤트를 처리하지 않음. `systemd-logind`가 처리하며, 기본값 `HandleLidSwitchDocked=ignore` 때문에 디스플레이가 2개 이상이면 뚜껑을 무시함.

## Change
`sudo`로 아래 drop-in 생성 후 logind reload:

`/etc/systemd/logind.conf.d/lid-always-suspend.conf`

```ini
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=suspend
EOF
```

Commands:

```bash
sudo mkdir -p /etc/systemd/logind.conf.d
sudo tee /etc/systemd/logind.conf.d/lid-always-suspend.conf ...
sudo systemctl reload systemd-logind
```

## Verify
`busctl get-property ... HandleLidSwitch HandleLidSwitchExternalPower HandleLidSwitchDocked` → 세 값 모두 `"suspend"`.

## Notes
- chezmoi 범위 밖(`/etc`)이라 홈 도트파일에는 넣지 않음.
- sudo 비밀번호/승인 프롬프트가 뜨면 사용자 입력이 필요함.