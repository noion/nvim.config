vim.api.nvim_create_autocmd('FileType', {
  pattern = 'java',
  callback = function()
    require('jdtls_config').setup_jdtls()
  end,
})
