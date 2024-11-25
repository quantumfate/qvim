local log = require("qvim.log").qvim

local M = {}

--- Initialize qvim default configuration and variables
--- This must be called at the beginning when qvim is
--- loaded since everything depends on this.
function M:init()
	---@class qvim
	---@field plugins Plugins
	---@field config config
	---@field format_on_save format_on_save
	---@field luasnip luasnip
	---@field icons icons
	---@field lsp table
	---@field autocommands autocommands
	_G.qvim = setmetatable(
		{},
		{ __index = vim.deepcopy(require("qvim.config.config")) }
	)

	vim.g.mapleader = qvim.config.leader
	vim.g.maplocalleader = qvim.config.leader
	local settings = require("qvim.config.settings")
	settings.load_defaults()

	---@return table languages
	function _G.qvim_languages()
		local languages = qvim.config.languages
		return languages
	end

	if not os.getenv("QV_FIRST_TIME_SETUP") then
		require("qvim.core").init_plugin_configurations()
		local qvim_lsp_config = require("qvim.lang.config")
		qvim.lsp = vim.deepcopy(qvim_lsp_config)
		vim.cmd.colorscheme(qvim.config.colorscheme)
	end

	log.info("Configs were loaded.")
end

return M
