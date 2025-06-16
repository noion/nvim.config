return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require 'harpoon'

    harpoon:setup()

    vim.keymap.set('n', '<leader>a', function()
      harpoon:list():add()
    end, { desc = 'Harpoon: Add file' })

    vim.keymap.set('n', '<leader>hh', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = 'Harpoon: Toggle quick menu' })

    local function setKey(fileId)
      vim.keymap.set('n', '<leader>h' .. fileId, function()
        harpoon:list():select(fileId)
      end, { desc = 'Harpoon: Navigate to file ' .. fileId })
    end

    setKey(1)
    setKey(2)
    setKey(3)
    setKey(4)

    -- Toggle previous & next buffers stored within Harpoon list
    local opts = { ui_nav_wrap = true }
    local modes = { 'n', 'i', 's' }
    vim.keymap.set(modes, '<C-M-p>', function()
      harpoon:list():prev(opts)
    end)
    vim.keymap.set(modes, '<C-M-n>', function()
      harpoon:list():next(opts)
    end)
  end,
}
