<!-- a708b536-6fa0-4c4d-b12e-6e05630bcd3b -->
# goodmorning + Slack MCP login

## 결론 (전역 auth)

**폴더 무관 전역 OAuth는 현재 불가능.** `~/.cursor/mcp.json`은 서버 *설정*만 전역이고, OAuth *토큰*은 workspace마다 `~/.cursor/projects/<id>/mcp-auth.json`에 저장된다.

그래서 per-workspace rule([`slack-mcp-auth.mdc`](/home/sungsik/.cursor/rules/slack-mcp-auth.mdc))을 없앨 조건(전역 인증)이 성립하지 않음 → **rule 유지**.

## 근거

- Agent CLI는 auth 경로를 `join(projectDir, "mcp-auth.json")`로 고정 (전역 store / `agent mcp login --global` 없음).
- 실측: 같은 머신에서 `~/.config` → slack ready, `~/projects` → requires_authentication.
- 토큰 hash도 project마다 다름 (공유 안 됨).
- docs의 “global”은 mcp.json 서버 정의용; OAuth credential store 공유가 아님. 커뮤니티/Multica도 per-project `mcp-auth.json`을 전제로 함.

비공식 우회(다른 project의 `mcp-auth.json` symlink/copy)는 가능해도 refresh race·지원 밖이라 추천하지 않음.

## goodmorning

[`~/.local/bin/goodmorning`](/home/sungsik/.local/bin/goodmorning)은 work 루틴(Twigate + Vay)이지만 **personal/work chezmoi 둘 다 unmanaged**. work가 추적하는 bin은 [`~/.local/bin/work/`](/home/sungsik/.local/bin/work/)뿐.

`agent mcp login slack`을 goodmorning에 넣어도 실행 cwd의 project에만 로그인됨 → **추가 비추천**.

## 추천 (변경 없음)

- Slack: 해당 workspace에서 온디맨드 `agent mcp login slack` + 기존 rule 유지
- goodmorning에 MCP login 넣지 않기
- (별도 요청 시) goodmorning/`vay-token-update`만 work chezmoi로 관리

구현은 요청 시에만 진행.
