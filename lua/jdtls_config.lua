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

-- Note: the field `name` must be a valid `ExecutionEnvironment`,
-- you can find the list here:
-- https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
--
-- This assumes you are using sdkman: https://sdkman.io
-- Paths must be absolute — jdtls does not expand `~`.
local function sdkman(version)
  return vim.fn.expand('~/.sdkman/candidates/java/' .. version)
end

local runtimes = {
  { name = 'JavaSE-17', path = sdkman '17.0.18-librca' },
  { name = 'JavaSE-21', path = sdkman '21.0.10-librca', default = true },
  { name = 'JavaSE-23', path = sdkman '23.0.2-tem' },
  { name = 'JavaSE-25', path = sdkman '25.0.4-tem' },
}

-- The mason `jdtls` script picks the equinox launcher and the platform config
-- directory itself, so neither has to be resolved here.
local function get_jdtls()
  local jdtls_path = vim.fn.expand '$MASON/packages/jdtls'
  -- Obtaing the path to lombok jar
  local lombok = jdtls_path .. '/lombok.jar'
  -- Obtaing the jdtls
  local jdtls = jdtls_path .. '/jdtls'
  return lombok, jdtls
end

local function get_bundles()
  local bundles = {}

  -- Include the whole java-test bundle set. It ships JUnit 5 and JUnit 6 side by
  -- side on purpose: `org.eclipse.jdt.junit5.runtime` requires
  -- `junit-jupiter-migrationsupport` in [5.14.0,6.0.0), so dropping the JUnit 5
  -- jars leaves that bundle unresolvable and breaks running tests. OSGi picks the
  -- right versions on its own.
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

-- Derived from the project root rather than the cwd, so that opening a file from
-- a subdirectory reuses the same workspace instead of re-indexing into a new one.
local function get_workspace(root_dir)
  local workspace_path = vim.fn.stdpath 'cache' .. '/jdtls/'
  local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')
  return workspace_path .. project_name
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

local function get_test_run_index_from_dap(method_name)
  -- Find the dap-repl buffer
  local buffers = vim.api.nvim_list_bufs()
  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name:match("dap%-repl") or buf_name:match("%[dap%-repl%]") then
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        
        -- Count test runs and find failures
        local run_count = 0
        local failure_indices = {}
        
        for i, line in ipairs(lines) do
          if line:match("✓%s+" .. method_name) or line:match("✗%s+" .. method_name) then
            run_count = run_count + 1
            if line:match("✗%s+" .. method_name) then
              table.insert(failure_indices, run_count)
            end
          end
        end
        
        return failure_indices
      end
    end
  end
  return {}
end

local function get_parameterized_test_info(file, method_name, line_num)
  -- Read the test file
  local ok, lines = pcall(vim.fn.readfile, file)
  if not ok or not lines then
    return nil
  end
  
  local method_line = nil
  local csv_source_content = ""
  local in_csv_source = false
  
  -- Find the method and its @CsvSource annotation
  for i, line in ipairs(lines) do
    if line:match("@CsvSource") then
      in_csv_source = true
      csv_source_content = line
    elseif in_csv_source and (line:match("^%s*%}") or line:match("^%s*%)")) then
      csv_source_content = csv_source_content .. "\n" .. line
      in_csv_source = false
    elseif in_csv_source then
      csv_source_content = csv_source_content .. "\n" .. line
    elseif line:match("void%s+" .. method_name .. "%s*%(") then
      method_line = i
      break
    end
  end
  
  if csv_source_content ~= "" then
    -- Parse CSV source values - handle multi-line strings properly
    local params = {}
    
    -- Extract everything between { and }
    local values_block = csv_source_content:match("%{(.-)%}")
    if values_block then
      -- Split by lines and extract quoted strings
      for line in values_block:gmatch("[^\r\n]+") do
        -- Match strings like: "print 1 + 2;, 3",
        local param = line:match('"(.-)"')
        if param then
          table.insert(params, param)
        end
      end
    end
    
    return params
  end
  
  return nil
end

local function enhance_quickfix_with_params()
  local qf_list = vim.fn.getqflist()
  local enhanced_count = 0
  
  -- Group entries by method to get failure indices
  local method_failures = {}
  
  for i, entry in ipairs(qf_list) do
    if entry.text and entry.valid == 1 then
      -- Extract method name from error text
      local method_name = entry.text:match("^(%w+)%s+org%.opentest4j") or 
                         entry.text:match("^(%w+)%s+") or
                         entry.text:match("^([%w_]+)")
      
      if method_name then
        if not method_failures[method_name] then
          method_failures[method_name] = {
            entries = {},
            indices = get_test_run_index_from_dap(method_name)
          }
        end
        table.insert(method_failures[method_name].entries, i)
      end
    end
  end
  
  -- Now enhance each entry with the correct parameter index
  for method_name, data in pairs(method_failures) do
    for idx, qf_idx in ipairs(data.entries) do
      local entry = qf_list[qf_idx]
      local param_index = data.indices[idx] or idx
      
      -- Get the file path
      local file_path = entry.bufnr and entry.bufnr > 0 and 
                       vim.api.nvim_buf_get_name(entry.bufnr) or 
                       vim.fn.bufname(entry.bufnr) or
                       entry.filename or ""
      
      if file_path ~= "" then
        -- Try to get parameter info
        local params = get_parameterized_test_info(file_path, method_name, entry.lnum)
        
        if params and params[param_index] then
          -- Enhance the text with parameter info
          local original_error = entry.text:match("org%.opentest4j%.AssertionFailedError:%s*(.+)") or
                                entry.text:match("expected:%s*(.+)") or
                                "assertion failed"
          
          entry.text = string.format("%s [param %d: %s] - %s", 
            method_name, 
            param_index,
            params[param_index]:sub(1, 60), -- Truncate long params
            original_error
          )
          enhanced_count = enhanced_count + 1
        end
      end
    end
  end
  
  if enhanced_count > 0 then
    -- Update quickfix with enhanced entries
    vim.fn.setqflist(qf_list, 'r')
    return true
  end
  return false
end

local function run_test_with_quickfix(test_func, desc)
  return function()
    -- Run the test
    test_func()
    
    -- Wait for test to complete and DAP to populate quickfix
    vim.defer_fn(function()
      local qf_list = vim.fn.getqflist()
      
      if #qf_list > 0 then
        -- Check if any failures
        local has_failures = false
        for _, entry in ipairs(qf_list) do
          if entry.type == 'E' or (entry.text and (entry.text:match("AssertionFailedError") or entry.text:match("error"))) then
            has_failures = true
            break
          end
        end
        
        if has_failures then
          -- Enhance quickfix entries with parameter information
          local enhanced = enhance_quickfix_with_params()
          vim.cmd('copen')
          if enhanced then
            vim.notify("Test failures enhanced with parameter info", vim.log.levels.WARN)
          else
            vim.notify("Test failures added to quickfix", vim.log.levels.WARN)
          end
        else
          vim.notify("All tests passed!", vim.log.levels.INFO)
        end
      end
    end, 3000) -- Wait 3 seconds for DAP to populate quickfix
  end
end

local function enable_debugger(bufnr)
  local jdtls = require 'jdtls'
  ---@diagnostic disable-next-line: missing-fields
  jdtls.setup_dap { hotcodereplace = 'auto' }
  require('jdtls.dap').setup_dap_main_class_configs()

  -- local opts = { buffer = bufnr }
  -- vim.keymap.set('n', '<leader>df', require('jdtls').test_class(), opts)
  -- vim.keymap.set('n', '<leader>dn', require('jdtls').test_nearest_method(), opts)

  vim.keymap.set('n', '<leader>Jt', run_test_with_quickfix(
    function() jdtls.test_nearest_method() end,
    'test method'
  ), { desc = '[J]ava: Run [T]est (with quickfix)', buffer = bufnr })
  
  vim.keymap.set('n', '<leader>JT', run_test_with_quickfix(
    function() jdtls.test_class() end,
    'test class'
  ), { desc = '[J]ava: Run [T]est Class (with quickfix)', buffer = bufnr })
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
    jdtls.extract_variable { visual = true }
  end, { desc = '[J]ava: Extract [V]ariable', buffer = bufnr })
  vim.keymap.set({ 'n', 'i' }, '<C-M-v>', function()
    jdtls.extract_variable()
  end, { desc = 'Java: Extract Variable', buffer = bufnr })
  vim.keymap.set('v', '<C-M-v>', function()
    jdtls.extract_variable { visual = true }
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
    jdtls.extract_method { visual = true }
  end, { desc = '[J]ava: Extract [M]ethod', buffer = bufnr })
  vim.keymap.set({ 'n', 'i' }, '<C-M-m>', function()
    jdtls.extract_method()
  end, { desc = 'Java: Extract Method', buffer = bufnr })
  vim.keymap.set('v', '<C-M-m>', function()
    jdtls.extract_method { visual = true }
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
  local function buf_set_option(option, value)
    vim.bo[bufnr][option] = value
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
    vim.lsp.buf.format { async = true }
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
  -- Get the path to lombok and to the jdtls launcher script
  local lombok, jdtlsFullPath = get_jdtls()
  -- Define the root directory of the project by looking for the specific markers
  local root_dir = jdtls.setup.find_root(root_files) or vim.fn.getcwd()
  -- Get the workspace directory
  local workspace_dir = get_workspace(root_dir)
  -- Get the bundles list with the jars to the debugger and testing
  local bundles = get_bundles()

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

  -- Set the command that starts the JDTLS server.
  --
  -- Only the launcher script's own options belong here: it already supplies the
  -- eclipse/osgi properties, `--add-modules`, `--add-opens`, the equinox jar and
  -- the platform config directory. Anything it does not recognise is appended
  -- *after* `-jar`, where it reaches the Eclipse application instead of the JVM
  -- and is silently ignored. JVM options have to go through `--jvm-arg=`, e.g.
  -- `--jvm-arg=-Xmx2g` to cap the heap or `--jvm-arg=-Dlog.level=ALL` for
  -- protocol logs. Without an explicit cap the JVM default applies.
  local cmd = {
    jdtlsFullPath,
    '--jvm-arg=-javaagent:' .. lombok,
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
      -- NOTE: every preference below has to stay inside this `java` table.
      -- jdtls only reads the `java.*` namespace, so anything placed next to it
      -- is silently ignored.
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
    root_dir = root_dir,
    flags = {
      allow_incremental_sync = true,
    },
    init_options = init_options,
  }
end

return {
  setup_jdtls = setup_jdtls,
}
