local M = {}
local Log = require("qvim.log")
local fn = require("qvim.utils.fn")
local meta = require("qvim.integrations._meta")

require("aieai")
---Populate the qvim.integrations table and defines how
---the table can be interacted with. And the following actions:
---- Runs a config method when the integration implements one.
---- A global function that returns the qvim.integrations table
---or a specific value when a key is specified
function M:init()
	local autocmds = require("qvim.integrations.autocmds")
	autocmds.load_defaults()

	local base = require("qvim.integrations._base")

	qvim.integrations = setmetatable({}, meta.integration_base_mt)

	for _, name in ipairs(_G.qvim_integrations()) do
		if _G.integration_provides_config(name) then
			local obj, instance = base:new(name)

			if obj and instance then
				qvim.integrations[name:gsub("-", "_")] = obj
				Log:debug(
					string.format(
						"The integration '%s' was added to the global qvim.integrations table. Referenced table is '%s'.",
						name,
						obj
					)
				)
				if instance.config then
					Log:debug(string.format("Config for '%s' was will be called as a function.", name))
					instance:config()
				end
			end
		else
			Log:debug(string.format("Integration '%s' does not provide a config.", name))
		end
	end

	---Returns a table with configured integrations or
	---a table of a specific integration when specified.
	---Integrations with hyphons will automatically
	---translated to underscores.
	---@param integration string? the name of an integration corresponding to the key in `qvim.integrations`
	---@return table integrations
	function _G.qvim_configured_integrations(integration)
		integration = fn.normalize(integration)
		if integration then
			return qvim.integrations[integration]
		end
		return qvim.integrations
	end

	Log:info("Integrations were loaded.")
end

return M
