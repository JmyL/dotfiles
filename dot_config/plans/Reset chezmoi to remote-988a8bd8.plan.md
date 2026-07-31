<!-- 988a8bd8-d3ef-4424-a681-a0ea2c566d2d -->
---
todos:
  - id: "update-personal"
    content: "chezmoi update --force (personal)"
    status: pending
  - id: "update-work"
    content: "gh auth switch to work, chezmoi-work update --force, switch back"
    status: pending
  - id: "docs-status"
    content: "Add chezmoi status reading notes to ~/.config/AGENTS.md"
    status: pending
  - id: "commit-docs"
    content: "chezmoi add AGENTS.md, commit and push personal repo"
    status: pending
  - id: "verify"
    content: "Confirm personal/work chezmoi status empty (except committed docs flow)"
    status: pending
isProject: false
---
# Document chezmoi status + reset live with update

## Why

이번 세션에서 status ` A`/` M`을 잘못 해석함. 공식 의미를 [`AGENTS.md`](/home/sungsik/.config/AGENTS.md)의 Dotfiles and chezmoi 절에 짧게 고정해 두고, 라이브 드리프트는 `chezmoi update`로 원격에 맞춘다. (`CLAUDE.md`는 `AGENTS.md` 심볼릭 링크라 한 파일만 수정.)

## Official `chezmoi status` (source of truth)

[chezmoi status](https://www.chezmoi.io/reference/commands/status/) — 출력은 `XY PATH`:

- **첫 열 (X):** chezmoi가 **마지막으로 쓴 상태** vs **현재 실제(라이브)** 차이
- **둘째 열 (Y):** **실제(라이브)** vs **target(소스에서 계산)** 차이 = `apply`가 할 일

| 문자 | 첫 열 | 둘째 열 |
|------|--------|---------|
| 공백 | 변화 없음 | 변화 없음 |
| `A` | (마지막 기록 이후) 항목이 생겼음 | apply 시 **생성** |
| `D` | 항목이 삭제됨 | apply 시 **삭제** |
| `M` | 항목이 수정됨 | apply 시 **수정** |
| `R` | n/a | 스크립트 실행 |

자주 보는 패턴:

- ` A` — 라이브에 없고 target에 있음 → apply/update가 **생성** (삭제 대상 아님)
- ` M` — 라이브는 마지막 write와 같거나 추적상 첫 열 무변인데 target과 다름 → apply가 **덮어씀** (예: pull 후 미적용)
- `MM` — 라이브가 마지막 write와도, target과도 다름 → apply 시 덮어쓰기 프롬프트 가능
- `D ` / ` D` — 각각 라이브에서 사라짐 / apply가 지움

원격으로 맞추기: `chezmoi update` (`git pull` + `apply`). 라이브 수정 전부 버릴 때는 `--force`.

## Steps

1. **Personal reset** — `chezmoi update --force` (현재 라이브 전용 드리프트·미적용 ` A` 반영)

2. **Work reset** — `gh auth switch --user sungsik-nam-vay` → `chezmoi --config ~/.config/chezmoi/chezmoi-work.toml update --force` → `gh auth switch --user JmyL`

3. **Document** — [`~/.config/AGENTS.md`](/home/sungsik/.config/AGENTS.md) `## Dotfiles and chezmoi` 아래에 짧은 하위절 추가:
   - status `XY` 두 열 의미 (위 공식 정의)
   - ` A` / ` M` / `MM` 해석 한 줄씩
   - 원격 동기화는 `chezmoi update` (+ work config 변형, 필요 시 `--force`)
   - 상세는 공식 status 페이지 링크

4. **Manage** — `chezmoi add ~/.config/AGENTS.md` → diff 확인 → personal 커밋·푸시 (`JmyL`)

5. **Verify** — personal/work `chezmoi status` 깨끗함 (docs 커밋 후)
