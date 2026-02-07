return {
  'AlexandrosAlexiou/kotlin.nvim',
  ft = { 'kotlin' },
  dependencies = { 'mason.nvim', 'mason-lspconfig.nvim', 'oil.nvim', 'trouble.nvim' },
  config = function()
    require('kotlin').setup {
      root_markers = {
        'gradlew',
        '.git',
        'mvnw',
        'settings.gradle',
      },
      -- Use bundled JRE from Mason (kotlin-lsp v261+)
      jre_path = nil,
      jvm_args = {
        '-Xmx4g',
      },
      inlay_hints = {
        enabled = true,
        parameters = true,
        types_property = true,
        types_variable = true,
        function_return = true,
        lambda_return = true,
      },
    }
  end,
}
