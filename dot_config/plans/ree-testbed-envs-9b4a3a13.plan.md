<!-- 9b4a3a13-1ea6-4c60-9f5d-86191347496f -->
---
todos:
  - id: "testbed-envs"
    content: "Create ~/.local/bin/ree-testbed-envs (source-safe VE/TS export)"
    status: pending
isProject: false
---
# `ree-testbed-envs` 추가

## 동작

```bash
source ree-testbed-envs loki   # bash
. ree-testbed-envs loki        # 동일 (POSIX synonym)
# → export VE=ve-de-loki TS=ts-de-ber-loki
```

- **반드시 `source` 또는 `.`로 실행.** 그냥 `ree-testbed-envs loki`로 실행하면 자식 프로세스에서만 export되고 부모 셸의 `$TS`/`$VE`는 안 바뀜.
- 인자 1개(testbed 이름) 필수. 없으면 usage 후 `return 1` (`exit` 금지 — source 시 부모 셸 종료 방지).
- 접두사는 고정: `ve-de-`, `ts-de-ber-`.
- bash에서 slash 없는 이름은 PATH에서 찾으므로 [`~/.local/bin/ree-testbed-envs`](/home/sungsik/.local/bin/ree-testbed-envs)에 두면 위처럼 호출 가능.

## 구현 요지

```bash
#!/usr/bin/env bash
# Usage: source ree-testbed-envs <name>   (or: . ree-testbed-envs <name>)
name="${1:?usage: source ree-testbed-envs <name>}"
export VE="ve-de-${name}"
export TS="ts-de-ber-${name}"
```

`set -euo pipefail` / `exit` 사용하지 않음 (source 안전).

## 범위

- 새 파일만: [`~/.local/bin/ree-testbed-envs`](/home/sungsik/.local/bin/ree-testbed-envs)
- 기존 `ree-ssh` / `ree-bootstrap` 변경 없음 (이미 `$TS`/`$VE` 사용).
- chezmoi: `.local/bin/ree-*` 이미 ignore됨 — 추가 ignore/커밋 없음.
