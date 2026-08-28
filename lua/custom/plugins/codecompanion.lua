-- Local AI via Ollama (qwen2.5-coder:7b for coding, qwen2.5:7b for general)
-- Keybindings use <leader>a*
return {
  {
    'olimorris/codecompanion.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {
      adapters = {
        ollama_coder = function()
          return require('codecompanion.adapters').extend('ollama', {
            name = 'ollama_coder',
            schema = {
              model = { default = 'qwen2.5-coder:7b' },
              num_ctx = { default = 16384 },
            },
          })
        end,
        ollama_chat = function()
          return require('codecompanion.adapters').extend('ollama', {
            name = 'ollama_chat',
            schema = {
              model = { default = 'qwen2.5:7b' },
              num_ctx = { default = 16384 },
            },
          })
        end,
      },
      strategies = {
        chat = { adapter = 'ollama_chat' },
        inline = { adapter = 'ollama_coder' },
        agent = { adapter = 'ollama_coder' },
      },
      display = {
        chat = {
          window = { width = 0.3 },
        },
      },
    },
    keys = {
      { '<leader>at', '<cmd>CodeCompanionChat Toggle<cr>',   desc = '[A]I Chat [T]oggle',         mode = { 'n', 'v' } },
      { '<leader>aa', '<cmd>CodeCompanionActions<cr>',       desc = '[A]I [A]ctions',              mode = { 'n', 'v' } },
      { '<leader>ai', '<cmd>CodeCompanion<cr>',              desc = '[A]I [I]nline',               mode = { 'n', 'v' } },
      { '<leader>af', ':CodeCompanionChat Add<cr>',          desc = '[A]I Add to chat',            mode = 'v' },
    },
  },
}
