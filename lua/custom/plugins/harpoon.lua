return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require 'harpoon'

    local function setKey(fileId)
      vim.keymap.set('n', '<leader>h' .. fileId, function()
        harpoon:list():select(fileId)
      end, { desc = 'Harpoon: Navigate to file ' .. fileId })
    end

    harpoon:setup()

    vim.keymap.set('n', '<leader>a', function()
      harpoon:list():add()
    end, { desc = 'Harpoon: Add file' })

    vim.keymap.set('n', '<leader>hh', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end)

    setKey(1)
    setKey(2)
    setKey(3)
    setKey(4)

    -- Toggle previous & next buffers stored within Harpoon list
    vim.keymap.set('n', '<C-M-P>', function()
      harpoon:list():prev()
    end)
    vim.keymap.set('n', '<C-M-N>', function()
      harpoon:list():next()
    end)
  end,
}
