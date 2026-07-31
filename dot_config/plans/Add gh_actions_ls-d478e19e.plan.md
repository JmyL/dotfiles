<!-- d478e19e-e9aa-48a6-a51e-d67c2b1d50aa -->
# Add `gh_actions_ls` to LSP servers

## Aerial 이번에 고친 것 (참고, 추가 작업 없음)

이전 [`aerial.lua`](lua/custom/plugins/aerial.lua):

```lua
init = function()
  vim.keymap.set('n', '<C-{>', ..., { buffer = bufnr })  -- bufnr 미정의 → 맵 깨짐
  vim.keymap.set('n', '<C-}>', ..., { buffer = bufnr })
  vim.keymap.set('n', '<leader>v', '<cmd>AerialToggle left<CR>')
end
```

지금:

- Prev/Next는 `opts.on_attach`에서 **실제 `bufnr`** 으로 버퍼 로컬 맵
- `<leader>v` 토글은 lazy `keys`로 전역 등록
- `buffer` → `buf` (0.12)

동작/키 조합 자체는 그대로이고, “안 되던 맵이 되게” 한 수정입니다.

## 변경

파일: [`lua/kickstart/plugins/lspconfig.lua`](lua/kickstart/plugins/lspconfig.lua)

`servers` 테이블에 추가 (nvim-lspconfig / Mason 매핑 이름: **`gh_actions_ls`**, Mason 패키지명 `gh-actions-language-server`와는 다름):

```lua
gh_actions_ls = {},
```

`ensure_installed`에 있는 `'gh-actions-language-server'`는 그대로 둡니다. `vim.tbl_keys(servers)`에도 `gh_actions_ls`가 들어가지만, mason-tool-installer가 lspconfig 이름을 패키지로 해석하거나 중복을 무시하므로 문제 없습니다.

기존 흐름이 그대로 적용됩니다: `vim.lsp.config` → `vim.lsp.enable(vim.tbl_keys(servers))`.

## 확인 / 커밋

- headless로 `gh_actions_ls`가 enable 목록에 있는지 확인
- 단독 커밋 후 종료
