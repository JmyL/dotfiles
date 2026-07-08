-- For more options, you can see `:help option-list`
vim.o.scrollback = 100000
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false
-- Sync clipboard between OS and Neovim.
-- Locally, use xsel so normal `p` can paste from the system clipboard.
-- In Herdr, use wl-paste for paste because Herdr does not answer OSC52 read
-- queries, while OSC52 copy/yank still works well.

local osc52 = require 'vim.ui.clipboard.osc52'

local function is_herdr()
  return vim.env.HERDR_PANE_ID ~= nil or vim.env.HERDR_TAB_ID ~= nil or vim.env.HERDR_WORKSPACE_ID ~= nil
end

local function is_aerc()
  return vim.env.AERC_ACCOUNT ~= nil
end

local function wl_paste(reg)
  local cmd = { 'wl-paste', '--type', 'text/plain;charset=utf-8' }
  if reg == '*' then
    table.insert(cmd, '--primary')
  end

  local raw = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    return { '' }, 'v'
  end

  local lines = vim.split(raw, '\n', { plain = true, trimempty = false })
  if raw ~= '' and raw:sub(-1) == '\n' then
    if lines[#lines] == '' then
      table.remove(lines, #lines)
    end
    return lines, 'V'
  end

  return lines, 'v'
end

local function paste_with_tmux_or_herdr(reg)
  return function()
    if (is_herdr() or is_aerc()) and vim.fn.executable 'wl-paste' == 1 then
      return wl_paste(reg)
    end

    if vim.env.TMUX then
      vim.fn.system { 'tmux', 'refresh-client', '-l' }
      vim.uv.sleep(100)
    end
    return osc52.paste(reg)()
  end
end

vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = osc52.copy '+',
    ['*'] = osc52.copy '*',
  },
  paste = {
    ['+'] = paste_with_tmux_or_herdr '+',
    ['*'] = paste_with_tmux_or_herdr '*',
  },
}

vim.opt.clipboard = 'unnamedplus'

vim.o.breakindent = true
vim.o.undofile = true
-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true
-- Keep signcolumn on by default
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true
vim.o.wrapscan = false
vim.o.linebreak = true
