<!-- 84eba03e-3912-4c65-8dae-8d5d32031193 -->
---
todos:
  - id: "revert-prev"
    content: "Revert prior slack:// open-url handler, desktop file, and mimeapps entries"
    status: pending
  - id: "remove-bad-ext"
    content: "Remove Open Slack in Browser, not App (polls interstitial, poor tab UX)"
    status: pending
  - id: "install-ext"
    content: "Install Force Slack in Browser (same-tab archives→messages at document_start)"
    status: pending
  - id: "tool-inventory"
    content: "Note Force Slack in Browser in tool-inventory.md"
    status: pending
  - id: "chezmoi"
    content: "chezmoi add reverted/updated files, diff, commit, push"
    status: pending
isProject: false
---
# Slack을 Brave에서 바로 웹으로 열기

## 원인

`https://<workspace>.slack.com/archives/...` 는 로컬 앱 유도 페이지를 띄운다. `archives` → `messages` 로 바꾸면 웹으로 바로 간다.

## 쓰지 않을 확장

이미 설치한 **[Open Slack in Browser, not App](https://chromewebstore.google.com/detail/open-slack-in-browser-not/jkgehijlkoolgcjifalbiicaomkngakb)** 는 제거한다.

동작이 나쁨: `archives` 페이지를 **먼저 로드**한 뒤 DOM에서 `/messages/` 링크를 최대 ~15초 polling하고 `location.href`로 다시 이동한다. 그래서 “탭이 열리고 → redirection → (사실상) Slack이 또 열리는” UX가 난다.

## 쓸 확장

**[Force Slack in Browser](https://chrome.google.com/webstore/detail/force-slack-in-browser/gfggogadjpapemlonlgpbofdeefkjakf)** (`gfggogadjpapemlonlgpbofdeefkjakf`)

- `document_start`에서 한 줄: `location` 의 `/archives/` → `/messages/` (같은 탭)
- 인터스티셜을 기다리지 않음

이전 OS/`open-url` `slack://` 핸들러는 **되돌린다** (확인 창 해결에 무관하고, 있으면 Brave가 연결된 앱을 더 물을 수 있음). `open-url`에 archives rewrite는 넣지 않음 (확장과 중복).

## 구현

### 1. 이전 수정 되돌리기

- [`open-url`](/home/sungsik/.local/bin/open-url): `slack://` 변환 제거
- `slack-web-url-handler.desktop` 삭제
- [`mimeapps.list`](/home/sungsik/.config/mimeapps.list): slack 핸들러 제거
- desktop DB / `xdg-mime` 확인

### 2. 확장 교체 (Brave)

- 제거: Open Slack in Browser, not App
- 설치: [Force Slack in Browser](https://chrome.google.com/webstore/detail/force-slack-in-browser/gfggogadjpapemlonlgpbofdeefkjakf)
- `brave://extensions` 에서 활성 확인

### 3. tool-inventory

[`tool-inventory.md`](/home/sungsik/.config/tool-inventory.md)에 Force Slack in Browser + 스토어 링크 기록. (잘못된 확장 이름은 적지 않음)

### 4. chezmoi

- `open-url`, `mimeapps.list`, desktop 삭제, `tool-inventory.md`
- diff → 커밋/푸시 (`JmyL`)

## 검증

- `archives` permalink 한 번만 같은 탭에서 `messages`로 바뀌어 웹 Slack이 열림
- 중간 interstitial 탭 / 추가 Slack 탭이 생기지 않음
- `app.slack.com/client/...` 핀 탭 정상
