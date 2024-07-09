local log = require("qvim.log").qvim

---@class nvim-dap-ui : nvim-dap
---@field enabled boolean|fun():boolean|nil
---@field name string|nil the human readable name
---@field options table|nil options used in the setup call of a neovim plugin
---@field keymaps keymaps|nil keymaps parsed to yikes.nvim
---@field main string|nil the string to use when the neovim plugin is required
---@field on_setup_start fun(self: nvim-dap-ui, instance: table|nil)|nil hook setup logic at the beginning of the setup call
---@field setup_ext fun(self: nvim-dap-ui)|nil overwrite the setup function in core_meta_ext
---@field on_setup_done fun(self: nvim-dap-ui, instance: table|nil)|nil hook setup logic at the end of the setup call
---@field url string neovim plugin url
local nvim_dap_ui = {
	enabled = true,
	name = nil,
	options = {
		auto_open = true,
		notify = {
			threshold = vim.log.levels.INFO,
		},
		config = {
			icons = { expanded = "", collapsed = "", circular = "" },
			mappings = {
				-- Use a table to apply multiple mappings
				expand = { "<CR>", "<2-LeftMouse>" },
				open = "o",
				remove = "d",
				edit = "e",
				repl = "r",
				toggle = "t",
			},
			-- Use this to override mappings for specific elements
			element_mappings = {},
			expand_lines = true,
			layouts = {
				{
					elements = {
						{ id = "scopes", size = 0.33 },
						{ id = "breakpoints", size = 0.17 },
						{ id = "stacks", size = 0.25 },
						{ id = "watches", size = 0.25 },
					},
					size = 0.33,
					position = "right",
				},
				{
					elements = {
						{ id = "repl", size = 0.45 },
						{ id = "console", size = 0.55 },
					},
					size = 0.27,
					position = "bottom",
				},
			},
			controls = {
				enabled = true,
				-- Display controls in this element
				element = "repl",
				icons = {
					pause = "",
					play = "",
					step_into = "",
					step_over = "",
					step_out = "",
					step_back = "",
					run_last = "",
					terminate = "",
				},
			},
			floating = {
				max_height = 0.9,
				max_width = 0.5, -- Floats will be treated as percentage of your screen.
				border = "rounded",
				mappings = {
					close = { "q", "<Esc>" },
				},
			},
			windows = { indent = 1 },
			render = {
				max_type_length = nil, -- Can be integer or nil.
				max_value_lines = 100, -- Can be integer or nil.
			},
		},
	},
	keymaps = {},
	main = "dapui",
	on_setup_start = nil,
	---@param self nvim-dap-ui
	setup_ext = function(self)
		local status_ok, ui = pcall(require, self.main)
		if not status_ok then
			log.warn(
				string.format("The extension '%s' could not be loaded.", ui)
			)
			return
		end

		local status_ok_dap, dap =
			pcall(require, getmetatable(self).__index.main)
		if not status_ok_dap then
			return
		end

		ui.setup(self.options)

		dap.listeners.after.event_initialized["dapui_config"] = function()
			ui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			ui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			ui.close()
		end

		-- until rcarriga/nvim-dap-ui#164 is fixed
		local function notify_handler(msg, level, opts)
			if level >= self.options.notify.threshold then
				return vim.notify(msg, level, opts)
			end

			opts = vim.tbl_extend("keep", opts or {}, {
				title = "dap-ui",
				icon = "",
				on_open = function(win)
					vim.api.nvim_buf_set_option(
						vim.api.nvim_win_get_buf(win),
						"filetype",
						"markdown"
					)
				end,
			})

			-- vim_log_level can be omitted
			if level == nil then
				level = log.levels["INFO"]
			elseif type(level) == "string" then
				level = log.levels[(level):upper()] or log.levels["INFO"]
			else
				-- https://github.com/neovim/neovim/blob/685cf398130c61c158401b992a1893c2405cd7d2/runtime/lua/vim/lsp/log.lua#L5
				level = level + 1
			end

			msg = string.format("%s: %s", opts.title, msg)
			log:add_entry(level, msg)
		end

		local dapui_ok, _ = xpcall(function()
			require(self.main .. ".util").notify = notify_handler
		end, debug.traceback)
		if not dapui_ok then
			log.debug("Unable to override dap-ui logging level")
		end

		if self.on_setup_done then
			self.on_setup_done(self, ui)
		end
	end,
	on_setup_done = nil,
	url = "https://github.com/rcarriga/nvim-dap-ui",
}

nvim_dap_ui.__index = nvim_dap_ui

return nvim_dap_ui
