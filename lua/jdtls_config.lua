local java_cmds = vim.api.nvim_create_augroup('java_cmds', { clear = true })

local cache_vars = {}

local root_files = {
  '.git',
  'mvnw',
  'gradlew',
  'pom.xml',
  'build.gradle',
  'build.gradle.kts',
  'build.sbt',
}

local features = {
  -- change this to `true` to enable codelens
  codelens = true,

  -- change this to `true` if you have `nvim-dap`,
  -- `java-test` and `java-debug-adapter` installed
  debugger = true,
}

local runtimes = {
  -- Note: the field `name` must be a valid `ExecutionEnvironment`,
  -- you can find the list here:
  -- https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
  --
  -- This example assume you are using sdkman: https://sdkman.io
  {
    name = 'JavaSE-17',
    path = '~/.sdkman/candidates/java/17.0.14-jbr',
  },
  {
    name = 'JavaSE-21',
    path = vim.fn.expand '~/.sdkman/candidates/java/21-tem',
    default = true,
  },
  {
    name = 'JavaSE-23',
    path = vim.fn.expand '~/.sdkman/candidates/java/23-tem',
  },
}

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
  local jdtls_path = vim.fn.expand '$MASON/packages/jdtls'
  -- Obtain the path to the JDTLS launcher jar
  local launcher = vim.fn.glob(jdtls_path .. '/plugins/org.eclipse.equinox.launcher_*.jar', true)
  -- Declare the system we are using, windows use win, osx use mac, linux use linux
  local config = jdtls_path .. get_config_path_name()
  -- Obtaing the path to lombok jar
  local lombok = jdtls_path .. '/lombok.jar'
  -- Obtaing the jdtls
  local jdtls = jdtls_path .. '/jdtls'
  return launcher, config, lombok, jdtls
end

local function get_bundles()
  local bundles = {}

  -- Include java-test bundle if present
  local java_test_path = vim.fn.expand '$MASON/packages/java-test'
  local java_test_bundle = vim.split(vim.fn.glob(java_test_path .. '/extension/server/*.jar'), '\n')
  if java_test_bundle[1] ~= '' then
    vim.list_extend(bundles, java_test_bundle)
  end

  -- Include java-debug-adapter bundle if present
  local java_debug_path = vim.fn.expand '$MASON/packages/java-debug-adapter'
  local java_debug_bundle = vim.split(vim.fn.glob(java_debug_path .. '/extension/server/com.microsoft.java.debug.plugin-*.jar'), '\n')
  if java_debug_bundle[1] ~= '' then
    vim.list_extend(bundles, java_debug_bundle)
  end

  return bundles
end

local function get_workspace()
  -- Get the home directory
  local home = os.getenv 'HOME'
  -- Directory where the workspace will be created
  local workspace_path = home .. '/.cache/nvim/jdtls/'
  -- Determint the project name
  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
  local workspace_dir = workspace_path .. project_name
  return workspace_dir
end

local function enable_codelens(bufnr)
  pcall(vim.lsp.codelens.refresh)

  vim.api.nvim_create_autocmd('BufWritePost', {
    buffer = bufnr,
    group = java_cmds,
    desc = 'refresh codelens',
    callback = function()
      pcall(vim.lsp.codelens.refresh)
    end,
  })
end

local function enable_debugger(bufnr)
  local jdtls = require 'jdtls'
  jdtls.setup_dap { hotcodereplace = 'auto' }
  require('jdtls.dap').setup_dap_main_class_configs()

  -- local opts = { buffer = bufnr }
  -- vim.keymap.set('n', '<leader>df', require('jdtls').test_class(), opts)
  -- vim.keymap.set('n', '<leader>dn', require('jdtls').test_nearest_method(), opts)

  vim.keymap.set('n', '<leader>Jt', function()
    jdtls.test_nearest_method()
  end, { desc = '[J]ava: Run [T]est', buffer = bufnr })
  vim.keymap.set('n', '<leader>JT', function()
    jdtls.test_class()
  end, { desc = '[J]ava: Run [T]est Class', buffer = bufnr })
end

local function java_keymaps(bufnr)
  -- Allow to run JdtCompile as Vim command
  vim.cmd "command! -buffer -nargs=? -complete=custom,v:lua.require('jdtls')._complete JdtCompile lua require('jdtls').compile(<f-args>)"
  -- Allow run JdtUpdateConfig as Vim command
  vim.cmd "command! -buffer JdtUpdateConfig lua require('jdtls').update_project_config()"
  vim.keymap.set('n', '<leader>Ju', function()
    vim.cmd 'JdtUpdateConfig'
  end, { desc = '[J]ava: [U]pdate Config', buffer = bufnr })
  -- Allow to run JdtBytecode as Vim command
  vim.cmd "command! -buffer JdtBytecode lua require('jdtls').javap()"
  -- Allow to run JdtShell as Vim command
  vim.cmd "command! -buffer JdtShell lua require('jdtls').jshell()"

  local jdtls = require 'jdtls'

  -- Set a Vim motion to organize imports
  vim.keymap.set('n', '<leader>Jo', function()
    jdtls.organize_imports()
  end, { desc = '[J]ava: [O]rganize Imports', buffer = bufnr })
  -- Set a Vim motion to extract a variable
  vim.keymap.set('n', '<leader>Jv', function()
    jdtls.extract_variable()
  end, { desc = '[J]ava: Extract [V]ariable', buffer = bufnr })
  vim.keymap.set('v', '<leader>Jv', function()
    jdtls.extract_variable(true)
  end, { desc = '[J]ava: Extract [V]ariable', buffer = bufnr })
  vim.keymap.set({ 'n', 'i' }, '<C-M-v>', function()
    jdtls.extract_variable()
  end, { desc = 'Java: Extract Variable', buffer = bufnr })
  vim.keymap.set('v', '<C-M-v>', function()
    jdtls.extract_variable(true)
  end, { desc = 'Java: Extract Variable', buffer = bufnr })
  -- Set a vim motion to extract a static variable
  vim.keymap.set({ 'n', 'v' }, '<leader>Js', function()
    jdtls.extract_constant()
  end, { desc = '[J]ava: Extract [S]tatic Variable', buffer = bufnr })
  -- Set a Vim motion to extract a method
  vim.keymap.set('n', '<leader>Jm', function()
    jdtls.extract_method()
  end, { desc = '[J]ava: Extract [M]ethod', buffer = bufnr })
  vim.keymap.set('v', '<leader>Jm', function()
    jdtls.extract_method(true)
  end, { desc = '[J]ava: Extract [M]ethod', buffer = bufnr })
  vim.keymap.set({ 'n', 'i' }, '<C-M-m>', function()
    jdtls.extract_method()
  end, { desc = 'Java: Extract Method', buffer = bufnr })
  vim.keymap.set('v', '<C-M-m>', function()
    jdtls.extract_method(true)
  end, { desc = 'Java: Extract Method', buffer = bufnr })

  -- Set a Vim motion to generate test for current class
  vim.keymap.set('n', '<leader>Jg', function()
    require('jdtls.tests').generate()
  end, { desc = '[J]ava: [G]enerate Test Methods', buffer = bufnr })
  vim.keymap.set('n', '<leader>gt', function()
    require('jdtls.tests').goto_subjects()
  end, { desc = '[G]oto [T]est Subjects', buffer = bufnr })

  -- local function buf_set_keymap(...)
  --   vim.api.nvim_buf_set_keymap(bufnr, ...)
  -- end
  local function buf_set_option(...)
    vim.api.nvim_buf_set_option(bufnr, ...)
  end

  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')
  vim.keymap.set('n', '<leader>wa', function()
    vim.lsp.buf.add_workspace_folder()
  end, { desc = '[W]orkspace: [A]dd Folder', buffer = bufnr })
  vim.keymap.set('n', '<leader>wr', function()
    vim.lsp.buf.remove_workspace_folder()
  end, { desc = '[W]orkspace: [R]emove Folder', buffer = bufnr })
  vim.keymap.set('n', '<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, { desc = '[W]orkspace: [L]ist Folders', buffer = bufnr })
  vim.keymap.set('n', '<leader>cf', function()
    vim.lsp.buf.formatting()
  end, { desc = '[C]ode: [F]ormat', buffer = bufnr })
end

local function jdtls_on_attach(_, bufnr)
  -- Set the keymaps for Java specific actions
  java_keymaps(bufnr)

  -- vim.lsp.inlay_hint(bufnr, true)
  if features.debugger then
    enable_debugger(bufnr)
  end

  if features.codelens then
    enable_codelens(bufnr)
  end

  -- Refresh the code lens to ensure they are up to date
  -- Code lenses enable features like reference count, implimentation count and more
  -- vim.lsp.codelens.refresh()

  -- Setup a function that automatically runs every time a java file is saved to refresh the code lens
  -- vim.api.nvim_create_autocmd('BufWritePost', {
  --   pattern = { '*.java' },
  --   callback = function()
  --     local _, _ = pcall(vim.lsp.codelens.refresh)
  --   end,
  -- })
end

local function setup_jdtls()
  local jdtls = require 'jdtls'
  -- Get the path to the JDTLS launcher jar, config and lombok jar
  local launch, config, lombok, jdtlsFullPath = get_jdtls()
  -- Get the workspace directory
  local workspace_dir = get_workspace()
  -- Get the bundles list with the jars to the debugger and testing
  local bundles = get_bundles()

  -- Define the root directory of the project by looking for the specific markers
  -- local root_dir = jdtls.setup.find_root(root_files)

  -- Tell our JDTLS language features it is capable of
  -- local capabilities = {
  --   workspace = {
  --     configuration = true,
  --   },
  --   textDocument = {
  --     completion = {
  --       snippetSupport = false,
  --     },
  --   },
  -- }

  -- Get the default extended client capabilities of the JDTLS
  local extendedClientCapabilities = jdtls.extendedClientCapabilities
  extendedClientCapabilities.onCompletionItemSelectedCommand = 'editor.action.triggerParameterHints'

  if cache_vars.capabilities == nil then
    jdtls.extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

    local ok_cmp, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
    cache_vars.capabilities = vim.tbl_deep_extend('force', vim.lsp.protocol.make_client_capabilities(), ok_cmp and cmp_lsp.default_capabilities() or {})
  end

  -- Set the command that starts the JDTLS server
  local cmd = {
    jdtlsFullPath,
    -- '~/.sdkman/candidates/java/21-tem/bin/java',
    'java', -- or '/path/to/java17_or_newer/bin/java'
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '--jvm-arg=-javaagent:' .. lombok,
    '-Xmx1g',
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
  local settings = {
    java = {
      project = {
        referencedLibraries = {
          -- add any library jars here for the lsp to pick them up
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
      -- If changes to the project will required the developer to update the project configuration advise the developer before applying the change
      configuration = {
        updateBuildConfiguration = 'interactive',
        runtimes = runtimes,
      },
      implementationsCodeLens = {
        enabled = true,
      },
      referencesCodeLens = {
        enabled = true,
      },
      references = {
        includeDecompiledSources = true,
      },
      inlayHints = {
        enabled = true,
        parameterNames = {
          enabled = 'all', -- literals, all, none
        },
      },
      format = {
        enabled = true,
        -- settings = {
        --   url = vim.fn.stdpath 'config' .. '/lang_servers/intellij-java-google-style.xml',
        --   profile = 'GoogleStyle',
        -- },
      },
    },

    signatureHelp = { enabled = true },
    -- Use the fernflower decompiler for Java files
    contentProvider = { preferred = 'fernflower' },
    saveActions = {
      organizeImports = true,
    },
    completion = {
      favoriteStaticMembers = {
        'org.hamcrest.MatcherAssert.assertThat',
        'org.hamcrest.Matchers.*',
        'org.hamcrest.CoreMatchers.*',
        'org.junit.jupiter.api.Assertions.*',
        'java.util.Objects.requireNonNull',
        'java.util.Objects.requireNonNullElse',
        'org.mockito.Mockito.*',
      },
      filteredTypes = {
        'com.sun.*',
        'java.awt.*',
        'jdk.*',
        'sun.*',
      },
    },
    extendedClientCapabilities = jdtls.extendedClientCapabilities,
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
  }

  local init_options = {
    bundles = bundles,
    extendedClientCapabilities = extendedClientCapabilities,
  }

  jdtls.start_or_attach {
    cmd = cmd,
    settings = settings,
    on_attach = jdtls_on_attach,
    capabilities = cache_vars.capabilities,
    root_dir = jdtls.setup.find_root(root_files), --root_dir,
    flags = {
      allow_incremental_sync = true,
    },
    init_options = init_options,
  }
end

return {
  setup_jdtls = setup_jdtls,
}
