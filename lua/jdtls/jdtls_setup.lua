local M = {}

function M.setup()
  local jdtls = require 'jdtls'
  local jdtls_dap = require 'jdtls.dap'
  local jdtls_setup = require 'jdtls.setup'

  local home = nil
  local path_to_mason_packages = nil

  local equinox_launcher_name = 'org.eclipse.equinox.launcher_1.7.0.v20250519-0528.jar'

  local runtimes = {}

  local java_executable = 'java'

  -- Version information from class file command : javap -verbose Sample.class | find "major"

  if vim.fn.has 'macunix' == 1 then
    runtimes = {
      {
        name = 'JavaSE-24',
        path = '/opt/homebrew/opt/openjdk@24/libexec/openjdk.jdk/Contents/Home/',
      },
    }
  else
    java_executable = 'C:/Program Files/Java/jdk-21/bin/java'
    runtimes = {
      {
        name = 'JavaSE-1.8',
        path = 'C:/Program Files/Java/jdk-1.8',
      },
      {
        name = 'JavaSE-21',
        path = 'C:/Program Files/Java/jdk-21',
      },
    }
  end

  if vim.fn.has 'macunix' == 1 then
    home = os.getenv 'HOME'
    path_to_mason_packages = home .. '/.local/share/nvim/mason/packages'
  else
    home = os.getenv 'UserProfile'
    path_to_mason_packages = home .. '/AppData/Local/nvim-data/mason/packages'
  end

  local path_to_jdtls = path_to_mason_packages .. '/jdtls'
  local path_to_jdebug = path_to_mason_packages .. '/java-debug-adapter'
  local path_to_jtest = path_to_mason_packages .. '/java-test'

  local path_to_config = nil
  if vim.fn.has 'macunix' == 1 then
    path_to_config = path_to_jdtls .. '/config_mac_arm'
  else
    path_to_config = path_to_jdtls .. '/config_win'
  end

  local root_markers = { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle', '.classpath', '.project' }
  local root_dir = jdtls_setup.find_root(root_markers)

  local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')
  -- Workspace Directory

  local metadata_directoryname = '.metadata'
  local ws_directory = vim.fn.fnamemodify(vim.fn.getcwd(), ':h')

  local ws_full_path = ws_directory .. '/' .. metadata_directoryname

  local workspace_dir = home .. '/.cache/jdtls/workspace' .. project_name
  if vim.fn.isdirectory(ws_full_path) then
    workspace_dir = ws_directory
  end

  --local path_to_config = path_to_jdtls .. '/config_linux'
  local lombok_path = path_to_jdtls .. '/lombok.jar'

  -- path to equinox launcher
  local path_to_jar = path_to_jdtls .. '/plugins/' .. equinox_launcher_name

  local bundles = {
    vim.fn.glob(path_to_jdebug .. '/extension/server/com.microsoft.java.debug.plugin-*.jar', true),
  }

  local function get_ws_jars()
    local jars = vim.split(vim.fn.glob(root_dir .. '/src/main/webapp/WEB-INF/lib/*.jar'), '\n')
    return jars
  end

  vim.list_extend(bundles, vim.split(vim.fn.glob(path_to_jtest .. '/extension/server/*.jar', true), '\n'))

  -- LSP settings for Java.

  local on_attach = function(_, bufnr)
    jdtls.setup_dap { hotcodereplace = 'auto' }
    jdtls_dap.setup_dap_main_class_configs()
    jdtls_setup.add_commands()

    -- Create a command `:Format` local to the LSP buffer
    vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
      vim.lsp.buf.format()
    end, { desc = 'Format current buffer with LSP' })

    require('lsp_signature').on_attach({
      bind = true,
      padding = '',
      handler_opts = {
        border = 'rounded',
      },
      hint_prefix = '󱄑 ',
    }, bufnr)

    -- NOTE: comment out if you don't use Lspsaga
    --require('lspsaga').init_lsp_saga()
  end

  local capabilities = {
    workspace = {
      configuration = true,
    },
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport = true,
        },
      },
    },
  }

  local config = {
    flags = {
      allow_incremental_sync = true,
    },
  }

  config.cmd = {
    --
    --'java', -- or '/path/to/java17_or_newer/bin/java'
    -- depends on if `java` is in your $PATH env variable and if it points to the right version.
    java_executable,
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xmx1g',
    '-javaagent:' .. lombok_path,
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',
    '-jar',
    path_to_jar,
    '-configuration',
    path_to_config,
    '-data',
    workspace_dir,
  }
  print(vim.fn.stdpath 'config')
  config.settings = {
    java = {
      references = {
        includeDecompiledSources = true,
      },
      format = {
        enabled = true,
        settings = {
          url = vim.fn.stdpath 'config' .. '/lang_servers/eclipse-java-google-style.xml',
          profile = 'GoogleStyle',
        },
      },
      eclipse = {
        downloadSources = true,
      },
      maven = {
        downloadSources = true,
      },
      signatureHelp = { enabled = true },
      contentProvider = { preferred = 'fernflower' },
      -- eclipse = {
      -- 	downloadSources = true,
      -- },
      -- implementationsCodeLens = {
      -- 	enabled = true,
      -- },
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
          'io.micrometer.shaded.*',
          'java.awt.*',
          'jdk.*',
          'sun.*',
        },
        importOrder = {
          'java',
          'javax',
          'com',
          'org',
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
      codeGeneration = {
        toString = {
          template = '${object.className}{${member.name()}=${member.value}, ${otherMembers}}',
          -- flags = {
          -- 	allow_incremental_sync = true,
          -- },
        },
        useBlocks = true,
      },
      configuration = {
        runtimes = runtimes,
      },
      project = {
        --referencedLibraries = {
        --  get_ws_jars(),
        -- vim.split(vim.fn.glob(root_dir .. '/src/main/webapp/WEB-INF/lib/*.jar')),
        --},
        -- referencedLibraries = get_ws_jars(),
      },
      symbols = {
        includeSourceMethodDeclarations = true,
      },
    },
  }

  config.on_attach = on_attach
  config.capabilities = capabilities
  config.on_init = function(client, _)
    client.notify('workspace/didChangeConfiguration', { settings = config.settings })
  end

  local extendedClientCapabilities = require('jdtls').extendedClientCapabilities
  extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

  config.init_options = {
    bundles = bundles,
    extendedClientCapabilities = extendedClientCapabilities,
  }

  -- Start Server
  require('jdtls').start_or_attach(config)

  -- Set Java Specific Keymaps
  require 'jdtls.keymaps'
end

return M
