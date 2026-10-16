-- Reading mode for prose buffers: strips the editing chrome (numbers, signs,
-- cursorline, inline diagnostics) and turns on soft wrapping, so a markdown file reads like a
-- document rather than source code. Pairs with render-markdown.nvim, which
-- does the actual drawing.
local M = {}

-- Window-local options swapped in while reading mode is on.
local reading_opts = {
  number = false,
  relativenumber = false,
  signcolumn = 'no',
  foldcolumn = '0',
  cursorline = false,
  list = false,
  spell = false,
  wrap = true,
  linebreak = true,
  breakindent = true,
}

-- Previous values, keyed by window id.
local saved = {}

local function get(win, name)
  return vim.api.nvim_get_option_value(name, { win = win, scope = 'local' })
end

local function set(win, name, value)
  vim.api.nvim_set_option_value(name, value, { win = win, scope = 'local' })
end

-- render-markdown is optional and lazy-loaded; never let it break the toggle.
local function render_markdown(action)
  local ok, plugin = pcall(require, 'render-markdown')
  if not ok or type(plugin[action]) ~= 'function' then
    return
  end
  pcall(plugin[action])
end

function M.is_enabled(win)
  win = win or vim.api.nvim_get_current_win()
  return saved[win] ~= nil
end

function M.enable(win)
  win = win or vim.api.nvim_get_current_win()
  if saved[win] then
    return
  end
  local previous = {}
  for name in pairs(reading_opts) do
    previous[name] = get(win, name)
  end
  -- Diagnostics are buffer-wide, so remember which buffer they were hidden in.
  local buf = vim.api.nvim_win_get_buf(win)
  saved[win] = {
    opts = previous,
    buf = buf,
    diagnostics = vim.diagnostic.is_enabled { bufnr = buf },
  }
  for name, value in pairs(reading_opts) do
    set(win, name, value)
  end
  vim.diagnostic.enable(false, { bufnr = buf })
  render_markdown 'buf_enable'
end

function M.disable(win)
  win = win or vim.api.nvim_get_current_win()
  local previous = saved[win]
  if not previous then
    return
  end
  saved[win] = nil
  for name, value in pairs(previous.opts) do
    set(win, name, value)
  end
  if previous.diagnostics and vim.api.nvim_buf_is_valid(previous.buf) then
    vim.diagnostic.enable(true, { bufnr = previous.buf })
  end
  render_markdown 'buf_disable'
end

function M.toggle(win)
  win = win or vim.api.nvim_get_current_win()
  if M.is_enabled(win) then
    M.disable(win)
  else
    M.enable(win)
  end
end

vim.api.nvim_create_autocmd('WinClosed', {
  group = vim.api.nvim_create_augroup('markdown-reader', { clear = true }),
  desc = 'Drop saved reading-mode options for closed windows',
  callback = function(ev)
    saved[tonumber(ev.match)] = nil
  end,
})

vim.api.nvim_create_user_command('MarkdownReader', function(opts)
  local action = opts.args ~= '' and opts.args or 'toggle'
  M[action]()
end, {
  nargs = '?',
  complete = function()
    return { 'toggle', 'enable', 'disable' }
  end,
  desc = 'Toggle markdown reading mode',
})

return M
