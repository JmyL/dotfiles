<!-- 9b4a3a13-1ea6-4c60-9f5d-86191347496f -->
---
todos:
  - id: "bootstrap-ts-ve"
    content: "ree-bootstrap: no-args fallback to $TS/$VE"
    status: pending
  - id: "ssh-export-ts-ve"
    content: "ree-ssh: export TS/VE into remote session after sudo su -"
    status: pending
isProject: false
---
# `$TS` / `$VE`를 bootstrap·ssh에 연결

## 동작

- 로컬 셸에서 `TS`/`VE`를 미리 export해 둔다고 가정 (예: `export TS=ts-… VE=ve-…`).
- [`ree-bootstrap`](/home/sungsik/.local/bin/ree-bootstrap): 인자 없음 → 설정된 `$TS`, `$VE`만 모아 부트스트랩. 둘 다 비어 있으면 에러. 하나만 있으면 그 호스트만.
- [`ree-ssh`](/home/sungsik/.local/bin/ree-ssh): 호스트 인자는 기존과 동일. `sudo su - <user>` 직후 원격 interactive 세션에 로컬 `$TS`/`$VE` 값을 `export` (비어 있어도 export는 함). 파일에 영구 저장하지 않음 — 해당 세션만.

## `ree-ssh` 원격 명령

`sudo su -`가 env를 지우므로, login 전환 **안쪽**에서 export한 뒤 셸을 띄움:

```bash
remote_cmd=$(printf 'export TS=%q VE=%q; exec "${SHELL:-bash}" -l' "${TS-}" "${VE-}")
exec ssh -t "$host" "$@" "exec sudo su - ${user} -c $(printf %q "$remote_cmd")"
```

## `ree-bootstrap` 호스트 선택

```bash
if [[ $# -eq 0 ]]; then
  set -- ${TS:+"$TS"} ${VE:+"$VE"}
  [[ $# -ge 1 ]] || { echo "usage: … or set TS/VE" >&2; exit 1; }
fi
```

인자로 호스트를 주면 기존처럼 인자만 사용 (`$TS`/`$VE`는 무시).

## 변경 파일

- [`~/.local/bin/ree-ssh`](/home/sungsik/.local/bin/ree-ssh)
- [`~/.local/bin/ree-bootstrap`](/home/sungsik/.local/bin/ree-bootstrap)

chezmoi 미추적 — ignore 추가 작업 없음.
