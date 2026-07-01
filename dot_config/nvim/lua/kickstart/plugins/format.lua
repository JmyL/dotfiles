return {
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true, cmake = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = 500,
            lsp_format = 'fallback',
          }
        end
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        bash = { 'shfmt' },
        yaml = { 'prettier' },
        tex = { 'latexindent' },
        nix = { 'alejandra' },
        proto = { 'buf' },
        cmake = { 'gersemi' },
        -- Keep Markdown formatting simple for Obsidian notes. The injected
        -- formatter can time out while scanning large wiki-style notes, and
        -- Prettier already handles the Markdown document itself.
        markdown = { 'prettier' },
        c = { 'clang-format' },
        cpp = { 'clang-format' },
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        -- javascript = { "prettierd", "prettier", stop_after_first = true },
      },
      formatters = {
        prettier = {
          prepend_args = { '--editorconfig' },
        },
        latexindent = {
          command = 'latexindent',
          args = { '-' },
          stdin = true,
        },
        ['clang-format'] = {
          args = { '--style=file:' .. vim.fn.expand('~/.clang-format') },
        },
      },
    },
  },
}
