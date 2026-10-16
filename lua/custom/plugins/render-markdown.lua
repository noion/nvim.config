-- In-buffer markdown rendering: headings, tables, code blocks and links are
-- drawn as decorations instead of raw text. Requires the `markdown` and
-- `markdown_inline` treesitter parsers (see kickstart/plugins/treesitter.lua).
return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'echasnovski/mini.icons',
    },
    ft = { 'markdown', 'codecompanion' },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      -- Also render codecompanion chat buffers, which are markdown underneath.
      file_types = { 'markdown', 'codecompanion' },
      -- Raw text comes back while editing the line the cursor is on.
      render_modes = { 'n', 'c', 't' },
      anti_conceal = { enabled = true },
      heading = {
        sign = false,
        position = 'inline',
        icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
        width = 'block',
        left_pad = 0,
        right_pad = 2,
      },
      code = {
        sign = false,
        style = 'full',
        width = 'block',
        left_pad = 2,
        right_pad = 2,
        min_width = 60,
        border = 'thick',
      },
      bullet = {
        icons = { '●', '○', '◆', '◇' },
      },
      checkbox = {
        unchecked = { icon = '󰄱 ' },
        checked = { icon = '󰱒 ' },
      },
      quote = { icon = '▍' },
      pipe_table = { preset = 'round' },
      link = {
        hyperlink = '󰌹 ',
        image = '󰥶 ',
        email = '󰀓 ',
      },
      sign = { enabled = false },
      -- LaTeX needs the external `latex2text` binary; off until it is wanted.
      latex = { enabled = false },
      win_options = {
        conceallevel = { rendered = 3 },
      },
    },
  },
}
