return {
  'linrongbin16/gitlinker.nvim',
  cmd = 'GitLink',
  opts = {},
  keys = {
    { '<leader>gy', '<cmd>GitLink<cr>', mode = { 'n', 'v' }, desc = 'Yank git link' },
    { '<leader>gY', '<cmd>GitLink!<cr>', mode = { 'n', 'v' }, desc = 'Open git link' },
  },
  config = function()
    require('gitlinker').setup {
      router = {
        browse = {
          ['^gitlab%.tcsbank%.ru'] = 'https://gitlab.tcsbank.ru/'
            .. '{_A.ORG}/'
            .. '{_A.REPO}/blob/'
            .. '{_A.REV}/'
            .. '{_A.FILE}'
            .. '#L{_A.LSTART}'
            .. "{_A.LEND > _A.LSTART and ('-' .. _A.LEND) or ''}",
        },
      },
    }
  end,
}
