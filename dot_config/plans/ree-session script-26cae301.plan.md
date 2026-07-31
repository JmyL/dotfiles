<!-- 26cae301-4055-4a94-9e08-cb9ab6fecf9d -->
---
todos:
  - id: "add-ree-session"
    content: "Create ~/.local/bin/ree-session (2x2, bootstrap, left TS / right VE via ree-ssh)"
    status: pending
isProject: false
---
# ree-session 스크립트

## 동작

```bash
ree-session <TS> <VE>
# 예: ree-session ts-de-ber-loki ve-de-loki
```

1. 인자 2개 필수 (`TS`, `VE` 순서). 없으면 usage 후 종료.
2. `export TS VE` 후 **`ree-bootstrap "$TS" "$VE"`** 실행 (기존 스크립트 재사용).
3. 세션 이름 **`ree`** 로 2x2 레이아웃 생성:
   - 왼쪽 열(pane 2개): `ree-ssh "$TS"`
   - 오른쪽 열(pane 2개): `ree-ssh "$VE"`
4. 각 pane에 `-e TS=... -e VE=...` 로 환경변수 전달 → 기존 [`ree-ssh`](/home/sungsik/.local/bin/ree-ssh)가 원격 셸에 `TS`/`VE`를 export하는 동작과 맞춤.
5. `select-layout tiled` 로 균등 분할 후 attach (`TMUX` 안이면 `switch-client`).

레이아웃:

```text
+--------+--------+
| TS     | VE     |
+--------+--------+
| TS     | VE     |
+--------+--------+
```

세션이 이미 있으면 **kill 후 재생성** (스크립트 한 번 실행 = bootstrap + 새 2x2 연결로 통일).

## 구현 요지

파일: [`~/.local/bin/ree-session`](/home/sungsik/.local/bin/ree-session) (실행 권한)

- `set -euo pipefail`, 기존 ree 스크립트와 같은 스타일
- 호스트는 `printf %q`로 이스케이프해서 pane command에 넣음
- pane 생성 순서:
  1. `new-session -d -s ree -e TS= -e VE= -- ree-ssh <TS>`
  2. `split-window -h ... -- ree-ssh <VE>`
  3. `split-window -v -t ree:0.0 ... -- ree-ssh <TS>`
  4. `split-window -v -t ree:0.2 ... -- ree-ssh <VE>`

## 범위 / 비범위

- **포함**: `~/.local/bin/ree-session` 추가만
- **제외**: `ree-ssh` / `ree-bootstrap` / `lib.sh` 변경 없음
- **chezmoi**: `.local/bin/ree-*` 이미 [`.chezmoiignore`](/home/sungsik/.local/share/chezmoi/.chezmoiignore)에 있음 → add/commit/push 없음
- **tool-inventory**: 새 외부 의존성 없음 (`tmux`, `ssh`는 기존)
