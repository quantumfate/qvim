---@class java ai
---@field setup function
local M = {}

local Log = require("qvim.log")
local fmt = string.format
---Setup the jdtls for java
---@return boolean server_started whether the jdtls server started
function M.setup()
	local status, jdtls = pcall(require, "jdtls")
	if not status then
		return false
	end

	-- Setup Workspace
	local home = os.getenv("HOME")
	local java_home = os.getenv("JAVA_HOME")
	local jdk_home = os.getenv("JDK_HOME")

	if not java_home then
		Log:error("Java home environment variable not set.")
	end

	if not jdk_home then
		Log:error("JDK home environment variable not set.")
	end

	local workspace_path = home .. "/.local/share/quantumvim/jdtls-workspace/"
	local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
	local workspace_dir = workspace_path .. project_name

	-- Determine OS
	local os_config = "linux"
	if vim.fn.has("mac") == 1 then
		os_config = "mac"
	end

	-- Setup Capabilities
	-- for completions
	local cmp_nvim_lsp = require("cmp_nvim_lsp")
	local client_capabilities = vim.lsp.protocol.make_client_capabilities()
	local capabilities = cmp_nvim_lsp.default_capabilities(client_capabilities)
	local extendedClientCapabilities = jdtls.extendedClientCapabilities
	extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

	-- Setup Testing and Debugging
	local bundles = {}
	local mason_path = vim.fn.glob(vim.fn.stdpath("data") .. "/mason/")
	vim.list_extend(bundles, vim.split(vim.fn.glob(mason_path .. "packages/java-test/extension/server/*.jar"), "\n"))
	vim.list_extend(
		bundles,
		vim.split(
			vim.fn.glob(
				mason_path .. "packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
			),
			"\n"
		)
	)

	local config = {
		cmd = {
			"java",
			"-Declipse.application=org.eclipse.jdt.ls.core.id1",
			"-Dosgi.bundles.defaultStartLevel=4",
			"-Declipse.product=org.eclipse.jdt.ls.core.product",
			"-Dlog.protocol=true",
			"-Dlog.level=ALL",
			"-Xms1g",
			"--add-modules=ALL-SYSTEM",
			"--add-opens",
			"java.base/java.util=ALL-UNNAMED",
			"--add-opens",
			"java.base/java.lang=ALL-UNNAMED",
			"-javaagent:" .. home .. "/.local/share/nvim/mason/packages/jdtls/lombok.jar",
			"-jar",
			vim.fn.glob(home .. "/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar"),
			"-configuration",
			home .. "/.local/share/nvim/mason/packages/jdtls/config_" .. os_config,
			"-data",
			workspace_dir,
		},
		root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", ".mvn" }),
		capabilities = vim.tbl_extend("keep", capabilities, {
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
		}),

		settings = {
			java = {
				eclipse = {
					downloadSources = true,
				},
				configuration = {
					updateBuildConfiguration = "automatic",
					maven = {
						userSettings = home .. "/.m2/settings.xml",
						globalSettings = home .. "/.m2/settings.xml",
					},
					runtimes = {
						-- Debian
						{
							name = "JavaSE-17",
							path = "/usr/lib/jvm/java-17-openjdk-amd64",
							javadoc = "/usr/lib/jvm/java-17-openjdk-amd64/docs/api",
							sources = "/usr/lib/jvm/java-17-openjdk-amd64/lib/src.zip",
						},
						{
							name = "JavaSE-20",
							path = "/usr/lib/jvm/java-20-openjdk-amd64",
							javadoc = "/usr/lib/jvm/java-20-openjdk-amd64/docs/api",
							sources = "/usr/lib/jvm/java-20-openjdk-amd64/lib/src.zip",
						},
						--Arch
						{
							name = "JavaSE-17",
							path = "/usr/lib/jvm/java-17-openjdk",
							javadoc = "/usr/share/doc/java17-openjdk/api",
							sources = "/usr/lib/jvm/java-17-openjdk/lib/src.zip",
						},
						{
							name = "JavaSE-20",
							path = "/usr/lib/jvm/java-20-openjdk",
							javadoc = "/usr/share/doc/java20-openjdk/api",
							sources = "/usr/lib/jvm/java-20-openjdk/lib/src.zip",
						},
					},
				},
				includeSourceMethodDeclarations = true,
				jdt = {
					ls = {
						androidSupport = true,
						lombokSupport = true,
						protofBufSupport = true,
					},
				},
				maven = {
					downloadSources = true,
				},
				implementationsCodeLens = {
					enabled = true,
				},
				signatureHelp = {
					true,
				},
				referencesCodeLens = {
					enabled = true,
				},
				references = {
					includeDecompiledSources = true,
				},
				inlayHints = {
					parameterNames = {
						enabled = "all", -- literals, all, none
					},
				},
				format = {
					enabled = false,
				},
			},
			extendedClientCapabilities = extendedClientCapabilities,
		},
		init_options = {
			bundles = bundles,
		},
	}

	config["on_attach"] = function(client, bufnr)
		local _, _ = pcall(vim.lsp.codelens.refresh)
		require("jdtls").setup_dap({ hotcodereplace = "auto" })
		require("qvim.lang.lsp").common_on_attach(client, bufnr)
		local status_ok, jdtls_dap = pcall(require, "jdtls.dap")
		if status_ok then
			jdtls_dap.setup_dap_main_class_configs()
		end
	end

	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		pattern = { "*.java" },
		callback = function()
			local _, _ = pcall(vim.lsp.codelens.refresh)
		end,
	})

	require("jdtls").start_or_attach(config)

	local keymaps = require("qvim.keymaps")

	keymaps:register({
		{
			binding_group = "C",
			name = "+Java",
			bindings = {
				o = { rhs = "<Cmd>lua require'jdtls'.organize_imports()<CR>", desc = "Organize Imports" },
				v = { rhs = "<Cmd>lua require('jdtls').extract_variable()<CR>", desc = "Extract Variable" },
				c = { rhs = "<Cmd>lua require('jdtls').extract_constant()<CR>", desc = "Extract Constant" },
				t = { rhs = "<Cmd>lua require'jdtls'.test_nearest_method()<CR>", desc = "Test Method" },
				T = { rhs = "<Cmd>lua require'jdtls'.test_class()<CR>", desc = "Test Class" },
				u = { rhs = "<Cmd>JdtUpdateConfig<CR>", desc = "Update Config" },
			},
			options = {
				prefix = "<leader>",
			},
		},
	})

	keymaps:register({
		{
			binding_group = "C",
			name = "+Java",
			bindings = {
				v = { rhs = "<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>", desc = "Extract Variable" },
				c = { rhs = "<Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>", desc = "Extract Constant" },
				m = { rhs = "<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>", desc = "Extract Method" },
			},
			options = {
				prefix = "<leader>",
				mode = "v",
			},
		},
	})

	vim.cmd(":set ft=java") -- weird hack ik for seme reason java filetype doesn't load after opening the first file
	return true
end

return M
