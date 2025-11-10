vim.cmd [[
    augroup jdtls_lsp
        autocmd!
        autocmd FileType java lua require'jdtls-config'.setup_jdtls()
    augroup end
]]
