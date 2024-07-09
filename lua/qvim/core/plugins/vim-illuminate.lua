---@class vim-illuminate : core_meta_plugin
---@field enabled boolean|fun():boolean|nil
---@field name string|nil the human readable name
---@field options table|nil options used in the setup call of a neovim plugin
---@field keymaps keymaps|nil keymaps parsed to yikes.nvim
---@field main string the string to use when the neovim plugin is required
---@field on_setup_start fun(self: vim-illuminate, instance: table)|nil hook setup logic at the beginning of the setup call
---@field setup fun(self: vim-illuminate)|nil overwrite the setup function in core_base
---@field on_setup_done fun(self: vim-illuminate, instance: table)|nil hook setup logic at the end of the setup call
---@field url string neovim plugin url
local vim_illuminate = {
	enabled = true,
	name = nil,
	options = { -- providers: provider used to get references in the buffer, ordered by priority
		providers = {
			"lsp",
			"treesitter",
			"regex",
		},
		-- delay: delay in milliseconds
		delay = 100,
		-- filetype_overrides: filetype specific overrides.
		-- The keys are strings to represent the filetype while the values are tables that
		-- supports the same keys passed to .configure except for filetypes_denylist and filetypes_allowlist
		filetype_overrides = {},
		-- filetypes_denylist: filetypes to not illuminate, this overrides filetypes_allowlist
		filetypes_denylist = {
			"dirvish",
			"fugitive",
		},
		-- filetypes_allowlist: filetypes to illuminate, this is overriden by filetypes_denylist
		filetypes_allowlist = {},
		-- modes_denylist: modes to not illuminate, this overrides modes_allowlist
		-- See `:help mode()` for possible values
		modes_denylist = {},
		-- modes_allowlist: modes to illuminate, this is overriden by modes_denylist
		-- See `:help mode()` for possible values
		modes_allowlist = {},
		-- providers_regex_syntax_denylist: syntax to not illuminate, this overrides providers_regex_syntax_allowlist
		-- Only applies to the 'regex' provider
		-- Use :echom synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
		providers_regex_syntax_denylist = {},
		-- providers_regex_syntax_allowlist: syntax to illuminate, this is overriden by providers_regex_syntax_denylist
		-- Only applies to the 'regex' provider
		-- Use :echom synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
		providers_regex_syntax_allowlist = {},
		-- under_cursor: whether or not to illuminate under the cursor
		under_cursor = true,
		-- large_file_cutoff: number of lines at which to use large_file_config
		-- The `under_cursor` option is disabled when this cutoff is hit
		large_file_cutoff = nil,
		-- large_file_config: config to use for large files (based on large_file_cutoff).
		-- Supports the same keys passed to .configure
		-- If nil, vim-illuminate will be disabled for large files.
		large_file_overrides = nil,
		-- min_count_to_highlight: minimum number of matches required to perform highlighting
		min_count_to_highlight = 1,
	},
	keymaps = {},
	main = "illuminate",
	on_setup_start = nil,
	---@param self vim-illuminate
	setup = function(self)
		local log = require("qvim.log").qvim
		local ok, vim_illuminate = pcall(require, self.main)
    local fmt = string.fmt
		if not ok then
			log.warn(fmt("The plugin '%s' could not be loaded.", self.name)
			return
		end
		vim_illuminate.configure(self.options)
	end,
	on_setup_done = nil,
	url = "https://github.com/RRethy/vim-illuminate",
}

vim_illuminate.__index = vim_illuminate

return vim_illuminate
