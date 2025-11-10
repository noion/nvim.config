-- INFO: only work for mac add here aditional os and arch if need https://luajit.org/ext_jit.html#jit_arch
local function get_os_arch()
  local arch = jit.arch
  local os = jit.os
  -- if arch arm or arm64 say arm
  if arch == 'arm' or arch == 'arm64' then
    arch = 'arm'
  elseif arch == 'x86' or arch == 'x64' then
    arch = ''
  end
  -- INFO: add here aditional os if need
  if os == 'OSX' then
    os = 'mac'
  end
  return os, arch
end

local function get_config_path_name()
  local os, arch = get_os_arch()
  if arch == '' then
    return '/config_' .. os
  end
  -- Return the path to the JDTLS config directory
  return '/config_' .. os .. '_' .. arch
end

local function get_jdtls()
  local jdtls_path = vim.fn.expand '$MASON/bin/jdtls'
  -- Obtain the path to the JDTLS launcher jar
  local launcher = vim.fn.glob(jdtls_path .. '/plugins/org.eclipse.equinox.launcher_*.jar')
  -- Declare the system we are using, windows use win, osx use mac, linux use linux
  local config = jdtls_path .. get_config_path_name()
  -- Obtaing the path to lombok jar
  local lombok = jdtls_path .. '/lombok.jar'
  return launcher, config, lombok
end

local function get_bundles()
  local java_debug_path = vim.fn.expand '$MASON/bin/java-debug-adapter'

  local bundles = {
    vim.fn.glob(java_debug_path .. '/extension/server/com.microsoft.java.debug.plugin-*.jar', true),
  }

  local java_test_path = vim.fn.expand '$MASON/bin/java-test'
  vim.list_extend(bundles, vim.split(vim.fn.glob(java_test_path .. '/extension/server/*.jar', true), '\n'))

  return bundles
end

local function get_workspace()
  -- Get the home directory
  local home = os.getenv 'HOME'
  -- Directory where the workspace will be created
  local workspace_path = home .. '/code/workspace/'
  -- Determint the project name
  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
  local workspace_dir = workspace_path .. project_name
  return workspace_dir
end

local function java_keymaps(bufnr)
  -- Allow to run JdtCompile as Vim command
  vim.cmd "command! -buffer -nargs=? -complete=custom,v:lua.require('jdtls')._complete JdtCompile lua require('jdtls').compile(<f-args>)"
  -- Allow run JdtUpdateConfig as Vim command
  vim.cmd "command! -buffer JdtUpdateConfig lua require('jdtls').update_project_config()"
  vim.keymap.set('n', '<leader>Ju', function()
    vim.cmd 'JdtUpdateConfig<CR>'
  end, { desc = '[J]ava: [U]pdate Config' })
  -- Allow to run JdtBytecode as Vim command
  vim.cmd "command! -buffer JdtBytecode lua require('jdtls').javap()"
  -- Allow to run JdtShell as Vim command
  vim.cmd "command! -buffer JdtShell lua require('jdtls').jshell()"

  -- Set a Vim motion to organize imports
  vim.keymap.set('n', '<leader>Jo', function()
    require('jdtls').organize_imports()
  end, { desc = '[J]ava: [O]rganize Imports' })
  -- Set a Vim motion to extract a variable
  vim.keymap.set({ 'n', 'v' }, '<leader>Jv', function()
    require('jdtls').extract_variable()
  end, { desc = '[J]ava: Extract [V]ariable' })
  vim.keymap.set('i', '<C-M-v>', function()
    require('jdtls').extract_variable()
  end, { desc = 'Java: Extract Variable' })
  -- Set a vim motion to extract a static variable
  vim.keymap.set({ 'n', 'v' }, '<leader>Jc', function()
    require('jdtls').extract_constant()
  end, { desc = '[J]ava: Extract [C]onstant Variable' })
  -- Set a Vim motion to extract a method
  vim.keymap.set({ 'n', 'v' }, '<leader>Jm', function()
    require('jdtls').extract_method()
  end, { desc = '[J]ava: Extract [M]ethod' })
  vim.keymap.set('i', '<C-M-m>', function()
    require('jdtls').extract_method()
  end, { desc = 'Java: Extract Method' })
  -- Set a Vim motion to run the current file
  vim.keymap.set({ 'n', 'v' }, '<leader>Jt', function()
    require('jdtls').test_nearest_method()
  end, { desc = '[J]ava: Run [T]est' })
  -- Set a Vim motion to run the current test
  vim.keymap.set('n', '<leader>JT', function()
    require('jdtls').test_class()
  end, { desc = '[J]ava: Run [T]est Class' })

  local function buf_set_keymap(...)
    vim.api.nvim_buf_set_keymap(bufnr, ...)
  end
  local function buf_set_option(...)
    vim.api.nvim_buf_set_option(bufnr, ...)
  end

  local opts = { noremap = true, silent = true }
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references() && vim.cmd("copen")<CR>', opts)
  buf_set_keymap('n', '<leader>ee', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<leader>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  -- Java specific
  buf_set_keymap('n', '<leader>di', "<Cmd>lua require'jdtls'.organize_imports()<CR>", opts)
  buf_set_keymap('n', '<leader>dt', "<Cmd>lua require'jdtls'.test_class()<CR>", opts)
  buf_set_keymap('n', '<leader>dn', "<Cmd>lua require'jdtls'.test_nearest_method()<CR>", opts)
  buf_set_keymap('v', '<leader>de', "<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>", opts)
  buf_set_keymap('n', '<leader>de', "<Cmd>lua require('jdtls').extract_variable()<CR>", opts)
  buf_set_keymap('v', '<leader>dm', "<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>", opts)

  buf_set_keymap('n', '<leader>cf', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)

  vim.api.nvim_exec(
    [[
          hi LspReferenceRead cterm=bold ctermbg=red guibg=LightYellow
          hi LspReferenceText cterm=bold ctermbg=red guibg=LightYellow
          hi LspReferenceWrite cterm=bold ctermbg=red guibg=LightYellow
          augroup lsp_document_highlight
            autocmd!
            autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
            autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
          augroup END
      ]],
    false
  )
end

local function setup_jdtls()
  local jdtls = require 'jdtls'
  -- Get the path to the JDTLS launcher jar, config and lombok jar
  local launch, config, lombok = get_jdtls()
  -- Get the workspace directory
  local workspace_dir = get_workspace()
  -- Get the bundles list with the jars to the debugger and testing
  local bundles = get_bundles()

  -- Define the root directory of the project by looking for the specific markers
  local root_dir = jdtls.setup.find_root { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle', 'build.kt' }

  -- Tell our JDTLS language features it is capable of
  local capabilities = {
    workspace = {
      configuration = true,
    },
    textDocument = {
      completion = {
        snippetSupport = false,
      },
    },
  }

  -- Get the default extended client capabilities of the JDTLS
  local extendedClientCapabilities = jdtls.extendedClientCapabilities
  extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

  -- Set the command that starts the JDTLS server
  local cmd = {
    'java', -- or '/path/to/java17_or_newer/bin/java'
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xmx1g',
    '-javaagent:' .. lombok,
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',
    '-jar',
    launch,
    '-configuration',
    config,
    '-data',
    workspace_dir,
  }

  -- Configure settings for the JDTLS server
  local settings_j = {
    java = {
      -- Format settings
      format = {
        enable = true,
        settings = {
          url = vim.fn.stdpath 'config' .. '/lang_servers/intellij-java-google-style.xml',
          profile = 'GoogleStyle',
        },
      },
      eclipse = {
        downloadSources = true,
        downloadJavadoc = true,
      },
      maven = {
        downloadSources = true,
        downloadJavadoc = true,
      },
      signatureHelp = { enabled = true },
      -- Use the fernflower decompiler for Java files
      contentProvider = { preferred = 'fernflower' },
      saveActions = {
        organizeImports = true,
      },
      completion = {
        favoriteStaticMembers = {
          'org.junit.jupiter.api.Assertions.*',
          'org.hamcrest.MatcherAssert.assertThat',
          'org.hamcrest.Matchers.*',
          'org.hamcrest.CoreMatchers.*',
          'org.mockito.Mockito.*',
        },
        filteredTypes = {
          'com.sun.*',
          'java.awt.*',
          'jdk.*',
          'sun.*',
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999, -- Disable auto import star
          staticStarThreshold = 9999, -- Disable auto import static star
        },
      },
      codeGeneration = {
        toString = {
          template = '${object.className}{${member.name()}=${member.value}, ${otherMembers}}',
        },
        hashCodeEquals = {
          useJava7Objects = true,
        },
        useBlocks = true,
      },
      -- If changes to the project will required the developer to update the project configuration advise the developer before applying the change
      configuration = {
        updateBuildConfiguration = 'interactive',
      },
      referencesCodeLens = {
        enabled = true,
      },
      inlayHints = {
        parameterNames = { enabled = 'all' },
      },
    },
  }

  local init_options = {
    bundles = bundles,
    extendedClientCapabilities = extendedClientCapabilities,
  }

  local on_attach = function(_, bufnr)
    -- Set the keymaps for Java specific actions
    java_keymaps(bufnr)

    require('jdtls.dap').setup_dap()

    -- Find the main nethod(s) of the application so the debug adapter can successfully start up the application
    -- Sometimes this will randomly fail if language server takes to long to startup for the project, if a ClassDefNotFoundException occurs when running
    -- the debug tool, attempt to run the debug tool while in the main class of the applition, or restart the neovim instance
    -- Unfortunately I have not found an elegant way to ensure this works 100%
    require('jdtls.dap').setup_dap_main_class_configs()

    require('jdtls_setup').setup.add_commands()

    -- Refresh the code lens to ensure they are up to date
    -- Code lenses enable features like reference count, implimentation count and more
    vim.lsp.codelens.refresh()

    require('lsp_signature').on_attach({
      bind = true,
      padding = '',
      handler_opts = {
        border = 'rounded',
      },
      hint_prefix = '󱄑 ',
    }, bufnr)

    -- Setup a function that automatically runs every time a java file is saved to refresh the code lens
    vim.api.nvim_create_autocmd('BufWritePost', {
      pattern = { '*.java' },
      callback = function()
        local _, _ = pcall(vim.lsp.codelens.refresh)
      end,
    })
  end

  jdtls.start_or_attach = {
    cmd = cmd,
    root_dir = root_dir,
    settings = settings_j,
    capabilities = capabilities,
    init_options = init_options,
    on_attach = on_attach(),
  }
end

return {
  setup_jdtls = setup_jdtls,
}
