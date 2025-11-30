local M = {}

M.mason_packages_path = ""
M.operating_system = ""
M.java_executable = "java"
M.runtimes = {}

if vim.fn.has("macunix") == 1 then
	local home = os.getenv("HOME")
	M.mason_packages_path = home .. "/.local/share/nvim/mason/packages"

	if vim.loop.os_uname().sysname == "Darwin" then
		M.operating_system = "mac_arm"
	else
		M.operating_system = "linux"
		M.runtimes = {
			{
				name = "JavaSE-24",
				path = "/opt/homebrew/opt/openjdk@24/libexec/openjdk.jdk/Contents/Home/",
			},
		}
	end
else
	local home = os.getenv("UserProfile")
	M.mason_packages_path = home .. "\\AppData\\Local\\nvim-data\\mason\\packages"
	M.operating_system = "win"

	M.java_executable = "C:\\Program Files\\Java\\jdk-21\\bin\\java"
	M.runtimes = {
		{
			name = "JavaSE-1.8",
			path = "C:\\Program Files\\Java\\jdk1.8.0_181",
			default = true,
		},
		{
			name = "JavaSE-21",
			path = "C:\\Program Files\\Java\\jdk-21",
		},
	}
end

local normalized_mason_path = vim.fs.normalize(M.mason_packages_path)
M.jdtls_path = vim.fs.joinpath(normalized_mason_path, "jdtls")
M.jdebug_path = vim.fs.joinpath(normalized_mason_path, "java-debug-adapter")
M.jtest_path = vim.fs.joinpath(normalized_mason_path, "java-test")

function M.get_jdtls()
	local launcher = vim.fn.glob(vim.fs.joinpath(M.jdtls_path, "plugins", "org.eclipse.equinox.launcher_*.jar"))
	local config_file = vim.fs.joinpath(M.jdtls_path, "config_" .. M.operating_system)
	local lombok = vim.fs.joinpath(M.jdtls_path, "lombok.jar")
	return launcher, config_file, lombok
end

function M.get_bundles()
	local bundles = {
		vim.fn.glob(vim.fs.joinpath(M.jdebug_path, "extension", "server", "com.microsoft.java.debug.plugin-*.jar")),
	}

	vim.list_extend(
		bundles,
		vim.split(vim.fn.glob(vim.fs.joinpath(M.jtest_path, "extension", "server", "*.jar"), 1), "\n")
	)
	return bundles
end

function M.get_workspace()
	local home = os.getenv("HOME")
	local cache_path = vim.fs.joinpath(home, ".cache", "jdtls")

	local current_working_directory = vim.fn.getcwd()
	local part1 = vim.fn.fnamemodify(current_working_directory, ":h:t")
	local part2 = vim.fn.fnamemodify(current_working_directory, ":t")
	local result = part1 .. "_" .. part2
	local workspace = vim.fs.joinpath(cache_path, "workspace" .. result)
	return workspace
end

function M.getJarFiles()
	local webcontent_jars = vim.fs.joinpath(vim.fn.getcwd(), "WebContent", "WEB-INF", "lib")
	if vim.fn.isdirectory(webcontent_jars) then
		local jarfilepath = vim.fs.joinpath(vim.fn.getcwd(), "WebContent", "WEB-INF", "lib", "*.jar")
		local jarfiles = vim.fn.split(vim.fn.glob(jarfilepath, true), "\n")
		print(type(jarfiles))
		return jarfiles
	else
		return {}
	end
end

function M.setup_jdtls()
	local jdtls = require("jdtls")
	local jdtls_dap = require("jdtls.dap")
	local jdtls_setup = require("jdtls.setup")

	local launcher, os_config, lombok = M.get_jdtls()

	local workspace_dir = M.get_workspace()
	local bundles = M.get_bundles()

	local root_dir = jdtls.setup.find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", ".classpath" })

	-- Capabilities -----
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

	--- Extended Capabilities -----------------
	local extendedCapabilities = jdtls.extendedClientCapabilities
	extendedCapabilities.resolveAdditionalTextEditsSupport = true

	--- Init Options ----------------------
	local init_options = {
		bundles = bundles,
		extendedCapabilities = extendedCapabilities,
	}

	---- Command  ---------------------------

	local command = {
		M.java_executable,
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.protocol=true",
		"-Dlog.level=ALL",
		"-Xmx1g",
		"-javaagent:" .. lombok,
		"--add-modules=ALL-SYSTEM",
		"--add-opens",
		"java.base/java.util=ALL-UNNAMED",
		"--add-opens",
		"java.base/java.lang=ALL-UNNAMED",
		"-jar",
		launcher,
		"-configuration",
		os_config,
		"-data",
		workspace_dir,
	}

	--- On Attach ------------------------
	local on_attach = function(_, bufnr)
		jdtls.setup_dap({ hotcodereplace = "auto" })
		jdtls_dap.setup_dap_main_class_configs()

		-- jdtls_setup.add_commands()
		vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
			vim.lsp.buf.format()
		end, { desc = "Format current buffer with LSP" })

		vim.lsp.codelens.refresh()

		require("lsp_signature").on_attach({
			bind = true,
			padding = "",
			handler_opts = {
				border = "rounded",
			},
			hint_prefix = "Hint:",
		}, bufnr)

		vim.api.nvim_create_autocmd("BufWritePost", {
			pattern = { "*.java" },
			callback = function()
				local _, _ = pcall(vim.lsp.codelens.refresh)
			end,
		})
	end

	--- Flags ----

	local flags = {
		allow_incremental_sync = true,
	}

	--- Settings --------

	local settings = {
		java = {
			references = {
				includeDecompiledSources = true,
			},
			format = {
				enabled = true,
				settings = {
					url = vim.fs.joinpath(vim.fn.stdpath("config"), "lang_servers", "eclipse-java-google-style.xml"),
					profile = "GoogleStyle",
				},
			},
			eclipse = {
				downloadSources = true,
			},
			maven = {
				downloadSources = true,
			},
			signatureHelp = {
				enabled = true,
			},
			contentProvider = {
				preferred = "fernflower",
			},
			-- implementationsCodeLens = {
			-- 	enabled = true,
			-- },
			completion = {
				favoriteStaticMembers = {
					"org.hamcrest.MatcherAssert.assertThat",
					"org.hamcrest.Matchers.*",
					"org.hamcrest.CoreMatchers.*",
					"org.junit.jupiter.api.Assertions.*",
					"java.util.Objects.requireNonNull",
					"java.util.Objects.requireNonNullElse",
					"org.mockito.Mockito.*",
				},
				filteredTypes = {
					"com.sun.*",
					"io.micrometer.shaded.*",
					"java.awt.*",
					"jdk.*",
					"sun.*",
				},
				importOrder = {
					"java",
					"jakarta",
					"javax",
					"com",
					"org",
				},
			},
			sources = {
				-- Threshhold to start combining reports
				organizeImports = {
					starThreshold = 9999,
					staticStarThreshold = 9999,
				},
			},
			codeGeneration = {
				-- When generating toString use json format
				toString = {
					template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
					-- flags = {
					-- 	allow_incremental_sync = true,
					-- },
				},
				hashCodeEquals = {
					useJava7Objects = true,
				},
				useBlocks = true,
			},
			configuration = {
				runtimes = M.runtimes,
				updateBuildConfiguration = "interactive",
			},
			project = {
				--referencedLibraries = {
				--  get_ws_jars(),
				-- vim.split(vim.fn.glob(root_dir .. '/src/main/webapp/WEB-INF/lib/*.jar')),
				--},
				--referencedLibraries = M.getJarFiles(),
			},
			-- enable code lens in the lsp
			referencesCodeLens = {
				enabled = true,
			},
			symbols = {
				includeSourceMethodDeclarations = true,
			},
			-- enable inlay hints for paramater names
			inlayHints = {
				parameterNames = {
					enabled = "all",
				},
			},
		},
	}

	--- On Init ----------------------------
	local on_init = function(client, _)
		client.notify("workspace/didChangeConfiguration", { settings = settings })
	end

	--- Config ---------------------------------

	local config = {
		cmd = command,
		root_dir = root_dir,
		flags = flags,
		capabilities = capabilities,
		init_options = init_options,
		settings = settings,
		on_attach = on_attach,
		on_init = on_init,
	}

	require("jdtls").start_or_attach(config)

	-- Set Java Specific Keymaps
	require("jdtls.keymaps")
end

return M
