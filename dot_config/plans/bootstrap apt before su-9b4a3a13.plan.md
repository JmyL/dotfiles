<!-- 9b4a3a13-1ea6-4c60-9f5d-86191347496f -->
---
todos:
  - id: "bootstrap-order"
    content: "Restructure ree-bootstrap: all apt -y installs first, then config sync via su"
    status: pending
isProject: false
---
# bootstrap: 설치를 계정 전환 전에 끝내기

## 문제

config sync는 `sudo su - <ree|nvidia>`가 필요하지만, apt 설치는 **로그인 계정**에서 `-y`로 해야 확인/비밀번호 프롬프트가 안 뜬다. 도구마다 install→sync를 섞으면 순서가 헷갈리고, sync 쪽 계정 전환과 섞이기 쉽다.

## 변경 ([`~/.local/bin/ree-bootstrap`](/home/sungsik/.local/bin/ree-bootstrap))

호스트당 두 단계로 분리:

1. **Install (로그인 유저, `sudo su` 없음)**  
   `ssh "$host" "apt-get install -y -- ${tools[*]}"`  
   — remote-tools 전체를 한 번에, `-y` 유지.
2. **Config sync (역할 유저)**  
   로컬 `~/.config/TOOL`이 있는 도구만, 기존처럼 `sudo su - $user`로 tar 동기화 (없으면 조용히 스킵).

```bash
echo "  install: ${tools[*]}"
ssh "$host" "apt-get install -y -- ${tools[*]}"

for tool in "${tools[@]}"; do
  [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/${tool}" ]] || continue
  echo "  sync config $tool"
  tar ... | ssh "$host" "sudo su - ${user} -c '...'"
done
```

chezmoi 변경 없음.
