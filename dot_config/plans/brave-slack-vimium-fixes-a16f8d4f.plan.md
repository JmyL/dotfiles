<!-- a16f8d4f-7d98-4e8f-9fe2-83376e99bbdc -->
---
todos:
  - id: "pack-script"
    content: "~/.local/bin/brave-install-local-extensions 작성: pem 생성/패킹, 확장 ID 계산, External Extensions JSON 작성"
    status: in_progress
  - id: "rules"
    content: "rules.json에 thread permalink 전용 고우선순위 규칙 추가 + 점 이스케이프 수정, manifest 버전 1.1.0으로 상향"
    status: pending
  - id: "shim"
    content: "crx 설치 확인 후 ~/.local/bin/brave-browser에서 --load-extension 제거"
    status: pending
  - id: "verify"
    content: "Brave 완전 재시작 후 thread URL이 인터스티셜 없이 app.slack.com 스레드로 가는지 검증"
    status: pending
  - id: "chezmoi"
    content: "tool-inventory.md 갱신, chezmoi add + diff 검토, JmyL로 커밋 및 push"
    status: pending
isProject: false
---

# Brave Slack 확장 상시 설치

한 번에 다 하지 않고 단계별로 진행한다.

## 조사 결과 (근본 원인)

**확장이 로드돼 있지 않음.** 현재 Brave 프로세스(PID 8238)는 7월 28일 17:27에 sway가 `sh -c brave-browser`로 띄운 것이고, PATH 상 `/usr/bin/brave-browser`가 잡혀 **`--load-extension` 없이** 실행 중입니다. sway config 101번 줄의 `~/.local/bin/brave-browser` 바인딩은 7월 29일에 고쳐졌지만 Brave는 그 전부터 계속 떠 있어서 적용되지 않았습니다.

브라우저 히스토리가 이를 확인해 줍니다 — 오늘 11:01:23에 문제의 thread 링크가 리다이렉트 표시 없이(`CHAIN_END`, 리다이렉트 플래그 없음) 그대로 열렸고, 12초 뒤 11:01:35에 사용자가 직접 `/messages/C06ETUGMAT1/p1781014234997039?thread_ts=1781009315.098239`로 이동했습니다. 확장이 살아 있었다면 즉시 리다이렉트됐어야 합니다. 즉 지금은 `--load-extension`으로 **cold start 할 때만** 확장이 붙는 취약한 구조입니다.

부수적으로 얻은 정보: Slack 인터스티셜의 "브라우저에서 열기" 링크는 `&cid=...`를 **떼고** `/messages/<C>/p<TS>?thread_ts=<T>` 형태를 쓰며, 이게 `app.slack.com/client/TAYJPCTCM/<C>/thread/...`로 정상 연결됩니다.

## 1. 확장을 .crx로 패킹해 상시 설치

새 스크립트 [~/.local/bin/brave-install-local-extensions](/home/sungsik/.local/bin/brave-install-local-extensions):

- 키/산출물은 chezmoi가 추적하는 트리 **바깥**인 `~/.local/state/brave-extensions/`에 둠 (`slack-stay-in-browser.pem`, `.crx`).
- pem이 없으면 생성되도록 `/usr/bin/brave-browser-stable --pack-extension=<src-dir> --pack-extension-key=<pem>` 실행.
- pem 공개키로 확장 ID 계산: DER 공개키 SHA-256의 앞 16바이트를 hex로 만든 뒤 `0-9a-f` → `a-p` 치환 (`openssl` + `python3`, `xxd` 의존 없이).
- `~/.config/BraveSoftware/Brave-Browser/External Extensions/<id>.json` 작성:

```json
{
  "external_crx": "/home/sungsik/.local/state/brave-extensions/slack-stay-in-browser.crx",
  "external_version": "1.1.0"
}
```

`external_version`은 `manifest.json`에서 읽어 채움. 작성 후 `bash -n`으로 검사하고 `shfmt -i 2` 스타일(2칸 들여쓰기, `((x))`, `case` 정렬) 준수.

폴백: Brave가 per-user External Extensions 디렉터리를 무시하면 시스템 경로 `/usr/share/brave/extensions/`를 쓰거나(추가 확인 필요), 그래도 안 되면 `--load-extension` 방식을 유지.

## 2. `rules.json` — thread permalink 전용 규칙

[~/.local/share/brave-extensions/slack-stay-in-browser/rules.json](/home/sungsik/.local/share/brave-extensions/slack-stay-in-browser/rules.json)에 우선순위 높은 규칙을 추가하고, 기존 규칙의 이스케이프되지 않은 `slack.com` 점도 수정:

- 신규 (priority 2): `^https://([^/]+)\.slack\.com/archives/([^/?]+)/(p\d+)\?(?:.*&)?thread_ts=([\d.]+).*$` → `https://\1.slack.com/messages/\2/\3?thread_ts=\4` — Slack 자신이 쓰는 URL과 정확히 동일한 형태로 만들고 `cid`는 버림.
- 기존 (priority 1): `^https://([^/]+)\.slack\.com/archives/(.*)$` → `https://\1.slack.com/messages/\2`.

`manifest.json` 버전을 `1.0.0` → `1.1.0`으로 올려 external_version 갱신이 재설치를 유발하게 함.

## 3. `~/.local/bin/brave-browser` 정리

crx 설치가 확인되면 shim에서 `--load-extension`을 제거해 단순 passthrough로 둡니다 (`.desktop`과 sway 바인딩이 이 경로를 참조하므로 파일 자체는 유지). 개발자 모드 경고와 확장 중복 로드를 피하기 위함입니다. crx 설치가 실패하면 이 단계는 건너뜁니다.

## 4. Brave 완전 재시작 후 검증

모든 Brave 창을 종료(3일째 떠 있는 인스턴스가 죽어야 함) 후 재시작하고, 터미널에서 문제의 thread URL을 열어 `app.slack.com/client/.../thread/...`로 바로 가는지 확인. 필요하면 `Preferences`의 확장 엔트리와 히스토리 리다이렉트 플래그로 재확인.

## 5. 문서 및 chezmoi 반영

- [~/.config/tool-inventory.md](/home/sungsik/.config/tool-inventory.md) 94번 줄의 설명을 새 설치 방식(crx + External Extensions, `brave-install-local-extensions` 실행)으로 갱신.
- personal chezmoi(`JmyL/dotfiles`, **public**)에 add: `~/.local/bin/brave-install-local-extensions`, `~/.local/share/brave-extensions/slack-stay-in-browser/{manifest.json,rules.json}`, `~/.local/bin/brave-browser`, `~/.config/tool-inventory.md`.
- `.pem`/`.crx`는 추적하지 않음(`~/.local/state/` 아래라 자동으로 제외). 워크스페이스 ID(`TAYJPCTCM`) 같은 업무 식별자는 public repo에 넣지 않음 — 그래서 `app.slack.com/client/<TEAM>/...` 직접 리다이렉트 방식은 채택하지 않았습니다.
- `chezmoi diff`로 검토 후 커밋하고 `JmyL`으로 push.
