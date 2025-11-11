vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('jdtls_lsp', { clear = true }),
  pattern = 'java',
  callback = function()
    require('jdtls-config').setup_jdtls()
  end,
})
