<!-- 93ce8629-a6c0-4bf8-aafb-d9ac7ce1a285 -->
---
todos:
  - id: "disable-tmuxinator-format"
    content: "format.lua format_on_save에서 ~/.config/tmuxinator/ 경로 스킵 추가"
    status: pending
isProject: false
---
# Disable autoformat for tmuxinator YAML

## Cause

맞습니다 — **부분적으로** `.editorconfig` 때문입니다. 다만 탭 설정만의 문제가 아니라, **저장 시 prettier가 돌아가면서** editorconfig를 적용하는 게 직접 원인입니다.

1. [`~/.editorconfig`](/home/sungsik/.editorconfig)의 `[*.{yml}]`이 `indent_size = 2`로 되어 있음
2. [`lua/kickstart/plugins/format.lua`](/home/sungsik/.config/nvim/lua/kickstart/plugins/format.lua)에서 YAML은 저장 시 `prettier`로 포맷되고, prettier에 `--editorconfig`가 붙어 있음

```41:41:lua/kickstart/plugins/format.lua
        yaml = { 'prettier' },
```

```57:60:lua/kickstart/plugins/format.lua
      formatters = {
        prettier = {
          prepend_args = { '--editorconfig' },
        },
```

3. tmuxinator 파일들은 **이미 들여쓰기가 섞여 있음** (일부 2칸: `dotfiles.yml`, `vifm.yml` 등 / 일부 4칸: `nvim.yml`, `ree-drive.yml` 등). 4칸짜리 파일을 저장하면 prettier가 editorconfig의 2칸으로 맞춤

`.editorconfig`만 고치면 전체 `*.yml` 기본값이 바뀌고, prettier가 다른 YAML 정규화도 할 수 있어 tmuxinator “지금 포맷 유지”에는 덜 맞음.

## Change

[`lua/kickstart/plugins/format.lua`](/home/sungsik/.config/nvim/lua/kickstart/plugins/format.lua)의 `format_on_save`에서 `~/.config/tmuxinator/` 아래 파일이면 `nil`을 반환해 autoformat을 건너뜀. 기존 `c`/`cpp`/`cmake` disable과 같은 패턴.

- 수동 `<leader>f`는 그대로 동작 (원하면 포맷 가능)
- 다른 YAML(CI, compose 등)의 format-on-save는 유지
- `.editorconfig`는 수정하지 않음

대략:

```lua
local path = vim.api.nvim_buf_get_name(bufnr)
if path:find('/%.config/tmuxinator/', 1, false) then
  return nil
end
```

## Verify

`nvim.yml`(4칸)을 열어 저장해도 들여쓰기가 2칸으로 바뀌지 않는지 확인.