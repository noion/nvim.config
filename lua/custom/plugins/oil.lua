return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    use_default_keymaps = false, -- Set to false to disable the default keymaps
    keymaps = {
      ['g?'] = { 'actions.show_help', mode = 'n' },
      ['<CR>'] = 'actions.select',
      ['<C-s>'] = { 'actions.select', opts = { vertical = true } },
      ['<C-_>'] = { 'actions.select', opts = { horizontal = true } },
      ['<C-t>'] = { 'actions.select', opts = { tab = true } },
      ['<C-p>'] = 'actions.preview',
      ['<C-c>'] = { 'actions.close', mode = 'n' },
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
    vim.keymap.set('n', '<leader>o', function()
      require('oil').open_float()
    end, { desc = 'Open oil in a floating window' }),
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
  -- Optional dependencies
  dependencies = { { 'echasnovski/mini.icons', opts = {} } },
  -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
  -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
  lazy = false,
  config = function(_, opts)
    require('oil').setup(opts)
  end,
}
