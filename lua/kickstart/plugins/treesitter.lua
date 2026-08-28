-- Parsers kept installed. `:TSInstall <lang>` adds one-off parsers, and any
-- filetype opened with a parser available upstream is installed on the fly.
local ensure_installed = {
  'bash',
  'c',
  'diff',
  'html',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'vim',
  'vimdoc',
  'python',
  'java',
  'kotlin',
  'sql',
  'go',
  'gomod',
  'gosum',
  'gotmpl',
}

-- Languages that depend on vim's regex highlighting for their indent rules:
-- they keep `syntax` on and are excluded from treesitter indentation.
local vim_regex_highlight = { ruby = true }

-- Highlighting is left off above this size; the parse cost is not worth it.
local max_filesize = 256 * 1024

return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    -- NOTE: `main` is the current rewrite. It has no `nvim-treesitter.configs`
    -- module, so parsers and highlighting are wired up by hand below instead of
    -- through `opts`.
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      local ts = require 'nvim-treesitter'
      ts.setup()

      local installed = {}
      local function refresh_installed()
        installed = {}
        for _, lang in ipairs(ts.get_installed 'parsers') do
          installed[lang] = true
        end
      end
      refresh_installed()

      ---@return boolean started
      local function enable(buf)
        if not vim.api.nvim_buf_is_valid(buf) then
          return false
        end
        local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
        if not lang or not installed[lang] then
          return false
        end
        if vim.fn.getfsize(vim.api.nvim_buf_get_name(buf)) > max_filesize then
          return false
        end
        if not pcall(vim.treesitter.start, buf, lang) then
          return false
        end
        if vim_regex_highlight[lang] then
          vim.bo[buf].syntax = 'ON'
        else
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
        return true
      end

      -- Install whatever is missing from `ensure_installed`, then light up the
      -- buffers that were already open while it downloaded.
      local missing = vim.tbl_filter(function(lang)
        return not installed[lang]
      end, ensure_installed)
      if #missing > 0 then
        ts.install(missing, { summary = true }):await(vim.schedule_wrap(function()
          refresh_installed()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) then
              enable(buf)
            end
          end
        end))
      end

      -- Resolved lazily: building the list pulls in the full parser table.
      local available
      local function is_available(lang)
        available = available or ts.get_available()
        return vim.list_contains(available, lang)
      end

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('kickstart-treesitter', { clear = true }),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
          if not lang then
            return
          end
          if installed[lang] then
            enable(ev.buf)
          elseif is_available(lang) then
            ts.install(lang):await(vim.schedule_wrap(function()
              refresh_installed()
              enable(ev.buf)
            end))
          end
        end,
      })
    end,
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  },
}
-- vim: ts=2 sts=2 sw=2 et
