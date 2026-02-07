return {
  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    -- Auto-download spell files before loading oil (oil disables NetRW)
    init = function()
      local spell_dir = vim.fn.stdpath 'data' .. '/site/spell'
      vim.fn.mkdir(spell_dir, 'p')
      
      -- Check if all required spell files exist
      local required_spells = { 'ru.utf-8.spl', 'en.utf-8.spl' }
      local missing = {}
      for _, spell_file in ipairs(required_spells) do
        if vim.fn.filereadable(spell_dir .. '/' .. spell_file) == 0 then
          table.insert(missing, spell_file:match('^(%w+)'))
        end
      end
      
      -- Download missing spell files before oil loads
      if #missing > 0 then
        vim.notify('Downloading missing spell files: ' .. table.concat(missing, ', '), vim.log.levels.INFO)
        -- Temporarily enable netrw for downloading
        vim.g.loaded_netrw = nil
        vim.g.loaded_netrwPlugin = nil
        
        for _, lang in ipairs(missing) do
          vim.cmd('silent! mkspell! ' .. spell_dir .. '/' .. lang .. '.utf-8.spl')
        end
        
        vim.notify('Spell files downloaded. Oil will now load.', vim.log.levels.INFO)
      end
    end,
    opts = {
      default_file_explorer = true,
      use_default_keymaps = false, -- Set to false to disable the default keymaps
      -- Skip confirmation for simple operations (copy, move, rename single files)
      skip_confirm_for_simple_edits = true,
      -- Prompt to save changes when selecting a new entry with modified buffer
      prompt_save_on_select_new_entry = false,
      win_options = {
        signcolumn = 'auto:2',
      },
      keymaps = {
        ['g?'] = { 'actions.show_help', mode = 'n' },
        ['<CR>'] = 'actions.select',
        ['<C-s>'] = { 'actions.select', opts = { vertical = true } },
        ['<C-_>'] = { 'actions.select', opts = { horizontal = true } },
        ['<C-t>'] = { 'actions.select', opts = { tab = true } },
        ['<C-p>'] = 'actions.preview',
        ['<C-c>'] = { 'actions.close', mode = 'n' },
        ['<Esc>'] = { 'actions.close', mode = 'n' },
        ['<C-r>'] = 'actions.refresh',
        ['-'] = { 'actions.parent', mode = 'n' },
        ['_'] = { 'actions.open_cwd', mode = 'n' },
        ['`'] = { 'actions.cd', mode = 'n' },
        ['~'] = { 'actions.cd', opts = { scope = 'tab' }, mode = 'n' },
        ['gs'] = { 'actions.change_sort', mode = 'n' },
        ['gx'] = 'actions.open_external',
        ['g.'] = { 'actions.toggle_hidden', mode = 'n' },
        ['g\\'] = { 'actions.toggle_trash', mode = 'n' },
      },
      -- Configuration for the floating window in oil.open_float
      float = {
        -- Padding around the floating window
        padding = 2,
        -- max_width and max_height can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        max_width = 0,
        max_height = 0,
        border = 'rounded',
        win_options = {
          winblend = 0,
          signcolumn = 'auto:2',
        },
        -- optionally override the oil buffers window title with custom function: fun(winid: integer): string
        get_win_title = nil,
        -- preview_split: Split direction: "auto", "left", "right", "above", "below".
        preview_split = 'auto',
        -- This is the config that will be passed to nvim_open_win.
        -- Change values here to customize the layout
        override = function(conf)
          return conf
        end,
      },
      view_options = {
        -- Show files and directories that start with "."
        show_hidden = true,
      },
    },
    keys = {
      {
        '<leader>o',
        function()
          require('oil').open_float()
        end,
        desc = 'Open oil in a floating window',
      },
    },
    -- Optional dependencies
    dependencies = { { 'echasnovski/mini.icons', opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
    config = function(_, opts)
      require('oil').setup(opts)
    end,
  },

  -- git integration for oil
  {
    -- https://github.com/refractalize/oil-git-status.nvim
    'refractalize/oil-git-status.nvim',

    dependencies = {
      'stevearc/oil.nvim',
    },

    config = true,
  },
}
