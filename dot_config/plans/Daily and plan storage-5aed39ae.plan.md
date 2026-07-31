<!-- 5aed39ae-0506-45e1-8d19-442f902d7c26 -->
# Daily 규칙 수정 + 계획 보관 위치

## 왜 Obsidian이 어색한가

Obsidian vault는 일상/업무 맥락(Jira·Slack·daily)용이다. `~/.local` swaync 빌드·sway/herdr 배선 같은 **에이전트 구현 플랜**은 이미 Cursor가 쓰는 [`~/.cursor/plans/Local swaync wiring-5aed39ae.plan.md`](/home/sungsik/.cursor/plans/Local%20swaync%20wiring-5aed39ae.plan.md)에 있다. 여기가 정본으로 충분하다 (작업 머신·Cursor 세션과 맞음). 별도 chezmoi `~/.config/plans/` 같은 새 관례는 만들지 않는다.

## 1. Obsidian `AGENTS.md` 규칙 수정

[`~/Documents/Obsidian/AGENTS.md`](/home/sungsik/Documents/Obsidian/AGENTS.md) Daily notes 섹션을 다음 취지로 바꾼다.

- **읽기:** 세션 시작/현재 작업 맥락용으로 오늘 daily를 읽는 것은 유지.
- **쓰기 금지(기본):** daily note를 **만들고·고치고·체크박스를 추가/삭제하지 않는다.** 사용자가 편집 중일 수 있다.
- **예외:** 사용자가 명시적으로 “daily에 넣어줘 / 오늘 노트에 …”라고 요청할 때만 오늘 `YYYY-MM-DD.md`를 수정.
- **구현 플랜:** 에이전트/인프라 how-to·배선 계획은 Obsidian에 두지 않는다. Cursor 작업이면 `~/.cursor/plans/`에 두고, 사용자가 다른 위치를 지정하면 그걸 따른다.

지금 있는 “Prefer appending actionable items…” / “When the user asks to put Slack/Jira work on the daily note…”는 **명시 요청 시에만** 적용되도록 문장을 좁힌다.

## 2. 홈 AGENTS에 한 줄 교차 참조

[`~/.config/AGENTS.md`](/home/sungsik/.config/AGENTS.md) (및 symlink된 `CLAUDE.md`)에 짧게:

- Obsidian vault 규칙은 `~/Documents/Obsidian/AGENTS.md`를 따른다.
- daily note는 사용자 명시 요청 없이 수정하지 않는다.

chezmoi: live 편집 후 personal `chezmoi add` → diff → commit/push.

## 3. 잘못 둔 Obsidian 사본 정리

- 삭제: [`~/Documents/Obsidian/1785495858-QQYY.md`](/home/sungsik/Documents/Obsidian/1785495858-QQYY.md)
- [`~/Documents/Obsidian/2026-07-31.md`](/home/sungsik/Documents/Obsidian/2026-07-31.md)에서 **우리가 넣은** `[[1785495858-QQYY|local swaync wiring]]` 체크박스 줄만 제거 (나머지 daily 내용은 건드리지 않음)

정본은 `~/.cursor/plans/Local swaync wiring-5aed39ae.plan.md` 유지. 나중에 실행할 때 그 파일(또는 이 대화)을 보면 된다.

## 범위

- Obsidian vault git commit은 사용자가 요청할 때만 (이번엔 파일 정리만 하거나, vault 커밋은 물어본 뒤).
- 새 `~/.config/plans/` 디렉터리나 Cursor rule 파일 추가는 하지 않음 (AGENTS로 충분).
