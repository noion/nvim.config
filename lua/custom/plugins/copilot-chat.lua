return {
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      { 'zbirenbaum/copilot.lua' }, -- or zbirenbaum/copilot.lua
      { 'nvim-lua/plenary.nvim', branch = 'master' }, -- for curl, log and async functions
    },
    build = 'make tiktoken', -- Only on MacOS or Linux
    -- opts = {
    -- See Configuration section for options
    -- providers = {
    --   github_models = {
    --     disabled = true,
    --   },
    -- },
    -- model = 'gpt-3.5-turbo',
    -- },
    -- See Commands section for default commands if you want to lazy load on them
    opts = function()
      local user = vim.env.USER or 'User'
      user = user:sub(1, 1):upper() .. user:sub(2)
      return {
        auto_insert_mode = true,
        question_header = '  ' .. user .. ' ',
        answer_header = '  Copilot ',
        window = {
          width = 0.3,
        },
      }
    end,
    config = function(_, opts)
      local chat = require 'CopilotChat'

      vim.api.nvim_create_autocmd('BufEnter', {
        pattern = 'copilot-chat',
        callback = function()
          vim.opt_local.relativenumber = false
          vim.opt_local.number = false
        end,
      })

      chat.setup(opts)
      
      -- Keybindings for inline code actions
      vim.keymap.set({'n', 'v'}, '<leader>cc', ':CopilotChat ', { desc = '[C]opilot [C]hat with prompt' })
      vim.keymap.set('v', '<leader>ce', ':CopilotChatExplain<CR>', { desc = '[C]opilot [E]xplain' })
      vim.keymap.set('v', '<leader>cr', ':CopilotChatReview<CR>', { desc = '[C]opilot [R]eview' })
      vim.keymap.set('v', '<leader>cf', ':CopilotChatFix<CR>', { desc = '[C]opilot [F]ix' })
      vim.keymap.set('v', '<leader>co', ':CopilotChatOptimize<CR>', { desc = '[C]opilot [O]ptimize' })
      vim.keymap.set('v', '<leader>cd', ':CopilotChatDocs<CR>', { desc = '[C]opilot [D]ocs' })
      vim.keymap.set('v', '<leader>ct', ':CopilotChatTests<CR>', { desc = '[C]opilot [T]ests' })
      vim.keymap.set('n', '<leader>cq', ':CopilotChatFixDiagnostic<CR>', { desc = '[C]opilot Fix Diagnostic' })
      vim.keymap.set('n', '<leader>cC', ':CopilotChatToggle<CR>', { desc = '[C]opilot Toggle Window' })
    end,
  },
}
