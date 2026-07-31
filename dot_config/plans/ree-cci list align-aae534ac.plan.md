<!-- aae534ac-a79a-4733-b706-0c8816219aa8 -->
---
todos:
  - id: "fix-list"
    content: "ree-cci list: pipe through column -t, use --no-headers"
    status: pending
  - id: "chezmoi-add"
    content: "chezmoi-work add + diff, then commit and push"
    status: pending
isProject: false
---
# Align `ree-cci list` columns

## Cause

[`~/.local/bin/work/ree-cci`](/home/sungsik/.local/bin/work/ree-cci) `list`는 TB마다 `kubectl get deploy`를 따로 호출하고, 첫 줄만 헤더를 두고 나머지는 `tail -1`로 이어 붙입니다. kubectl은 **호출마다** NAME 길이에 맞춰 공백을 잡기 때문에, 합치면 이렇게 어긋납니다:

```
athena-machine-runner   0/0     ...
demeter-machine-runner   1/1     ...   # 앞 공백 폭이 다름
odin-machine-runner   0/0     ...
```

## Change

`list` 분기만 수정:

```bash
list)
  {
    first=true
    for tb in "${tbs[@]}"
    do
      if $first
      then
        kubectl get deploy -n "circleci-$tb"
        first=false
      else
        kubectl get deploy -n "circleci-$tb" --no-headers
      fi
    done
  } | column -t
  ;;
```

- 출력을 한 스트림으로 모은 뒤 `column -t`로 전체 컬럼 폭을 맞춤
- `tail -1` → `--no-headers` (헤더만 제거하고, 해당 ns에 deploy가 여러 개여도 모두 표시)
- `column`은 Ubuntu/Fedora 모두 기본 제공

## Chezmoi

파일이 아직 work chezmoi에 **unmanaged**입니다. 라이브 수정 후:

1. `chezmoi --config ~/.config/chezmoi/chezmoi-work.toml add ~/.local/bin/work/ree-cci`
2. `chezmoi --config ... diff`로 확인
3. work 레포 commit + `sungsik-nam-vay`로 push
