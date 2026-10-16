-- Markdown specific settings (window/buffer local: these must not leak into
-- the next buffer opened in this window)
vim.opt_local.wrap = true -- Wrap text
vim.opt_local.breakindent = true -- Match indent on line break
vim.opt_local.linebreak = true -- Line break on whole words
-- NOTE: `conceallevel` is left alone on purpose: render-markdown raises it
-- while rendering and restores it when the cursor enters the line.

-- Allow j/k when navigating wrapped lines
vim.keymap.set('n', 'j', 'gj', { buffer = true, desc = 'Down by display line' })
vim.keymap.set('n', 'k', 'gk', { buffer = true, desc = 'Up by display line' })

local reader = require 'custom.markdown_reader'

vim.keymap.set('n', '<leader>mv', reader.toggle, { buffer = true, desc = 'Markdown: toggle [V]iew mode' })
vim.keymap.set('n', '<leader>mr', '<cmd>RenderMarkdown buf_toggle<CR>', { buffer = true, desc = 'Markdown: toggle [R]endering' })
