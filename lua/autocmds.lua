-- Setup JDTLS for Java files
-- vim.api.nvim_create_autocmd('FileType', {
--   group = vim.api.nvim_create_augroup('jdtls_lsp', { clear = true }),
--   pattern = 'java',
--   callback = require('lsp.jdtls').setup_jdtls,
-- })

-- Gradle files syntax highlighting
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = { '*.gradle', '*.gradle.kts', 'build.gradle', 'build.gradle.kts', 'settings.gradle', 'settings.gradle.kts' },
  callback = function()
    vim.bo.filetype = 'groovy'
  end,
})
