vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('jdtls_lsp', { clear = true }),
  pattern = 'java',
  callback = function()
    print 'jdtls autocmd triggered'
    require('jdtls-config').setup_jdtls()
  end,
})
