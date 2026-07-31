<!-- 054ed25e-626c-428a-ad91-def9f515685d -->
---
todos:
  - id: "editorconfig-mount"
    content: "rddev-devenv shim: .editorconfig를 $HOME/.editorconfig 동일 경로로 마운트 + has_devenv_mounts 갱신"
    status: pending
  - id: "verify-editorconfig"
    content: "bootstrap/restart 후 컨테이너에서 /home/sungsik/.editorconfig 존재 확인"
    status: pending
isProject: false
---
# `.editorconfig`를 호스트 홈 경로에 마운트

## 원인

EditorConfig는 `/home/ree/.editorconfig`를 “유저 설정”으로 보지 않고, **편집 중인 파일 디렉터리 → 상위**로 `.editorconfig`를 찾습니다 (`root = true`까지).

지금 rddev workdir는 [`/home/sungsik/projects/ree-drive`](misc/rddev) (호스트 경로 그대로). 상향 탐색:

`.../ree-drive` → `.../projects` → `/home/ree`가 아니라 **`/home/sungsik`**

컨테이너 안 `/home/sungsik`에는 `projects/` stub만 있고 `~/.editorconfig`가 없음.  
현재 마운트 `/home/ree/.editorconfig`는 `/home/ree/ree-drive/...`로 열 때만 유효.

## 수정

[`~/.local/bin/rddev-devenv`](~/.local/bin/rddev-devenv) shim:

- 기존: `-v "$HOME/.editorconfig:/home/ree/.editorconfig:ro"`
- 변경: `-v "$EDITORCONFIG_HOST:$EDITORCONFIG_HOST:ro"`  
  (`EDITORCONFIG_HOST`는 이미 `${HOME}/.editorconfig`)

`has_devenv_mounts` 검사도 `/home/ree/.editorconfig` → 실제 `$EDITORCONFIG_HOST` 경로로 맞춤.

`bootstrap`/`restart` 한 번이면 workdir 트리에서 `/home/sungsik/.editorconfig`가 보임.

`/home/ree/ree-drive`로도 자주 연다면 그 경로용으로 `/home/ree/.editorconfig` 마운트를 **추가로** 유지할 수 있으나, workdir 기준이면 호스트 홈 경로 한 곳이면 충분하므로 **그걸로 교체**한다.
