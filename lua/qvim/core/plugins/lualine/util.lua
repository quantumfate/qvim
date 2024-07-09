local lualine_util = {}

local log = require("qvim.log").qvim
local fmt = string.format

---@return colors
function lualine_util.get_colors()
	---@class colors
	---@field	rosewater string
	---@field	flamingo string
	---@field	pink string
	---@field	mauve string
	---@field	red string
	---@field	maroon string
	---@field	peach string
	---@field	yellow string
	---@field	green string
	---@field	teal string
	---@field	sky string
	---@field	sapphire string
	---@field	blue string
	---@field	lavender string
	---@field	text string
	---@field	subtext1 string
	---@field	subtext0 string
	---@field	overlay2 string
	---@field	overlay1 string
	---@field	overlay0 string
	---@field	surface2 string
	---@field	surface1 string
	---@field	surface0 string
	---@field	base string
	---@field	mantle string
	---@field	crust string
	return require("catppuccin.palettes").get_palette("mocha")
end

function lualine_util.env_cleanup(venv)
	if string.find(venv, "/") then
		local final_venv = venv
		for w in venv:gmatch("([^/]+)") do
			final_venv = w
		end
		venv = final_venv
	end
	return venv
end

---@param displayed string
function lualine_util.unified_format(displayed)
	return displayed:lower()
end

---Takes a list of strings, makes them unique and concatenates them by a separator
---@param list table<string>
---@param sep string|nil
---@param limit number|nil the amount of items that should be displayed before the third item becomes the total count of items not displayed
---@return string
function lualine_util.unique_list_string_format(list, sep, limit)
	sep = sep or ", "
	limit = limit or 1
	local unique_list = {}
	for _, item in pairs(list) do
		if not vim.tbl_contains(unique_list, item) then
			table.insert(unique_list, item)
		end
	end
	if limit > 0 and #unique_list > limit then
		return unique_list[1] .. " +" .. tostring(#unique_list - 1)
	elseif #unique_list > 1 then
		return table.concat(unique_list, sep)
	else
		return unique_list[1] or ""
	end
end

---Returns a string formatted by a unique list of methods on the current filetype
---@param method string
---@param sep string|nil
---@return string|nil
function lualine_util.get_registered_methods(method, sep)
	local buf_ft = vim.bo.filetype
	local ok, method_service =
		pcall(require, "qvim.lang.null-ls.methodservice." .. method)
	if ok then
		local supported_diagnostics = method_service:list_registered(buf_ft)
		if method == "code_actions" then
			return lualine_util.unique_list_string_format(
				supported_diagnostics,
				sep
			)
		else
			return lualine_util.unique_list_string_format(
				supported_diagnostics,
				sep,
				2
			)
		end
	else
		log.error(fmt("[lualine] Invalid method '%s'", method))
		return nil
	end
end

---@param letter string
---@param modifier string|nil BoxFull, BoxOutline, CircleFull, CircleOutline or nil for normal symbol
---@return string|nil result the symbol or nil
function lualine_util.get_symbol(letter, modifier)
	local lookup
	if modifier then
		lookup = string.upper(letter) .. modifier
	else
		lookup = string.upper(letter)
	end
	if qvim.icons.signs[lookup] then
		return qvim.icons.signs[lookup]
	else
		return nil
	end
end

---@param branch_name string
---@param max_length number
---@return string
function lualine_util.shorten_branch_name(branch_name, max_length)
	if #branch_name <= max_length then
		return branch_name
	end

	local parts = {}
	for part in string.gmatch(branch_name, "([^-%/]+)") do
		table.insert(parts, part)
	end

	if #parts == 1 then
		return branch_name:sub(1, max_length) .. "..."
	end

	local new_branch_name = ""
	for i, part in ipairs(parts) do
		if #new_branch_name + #part > max_length then
			break
		end
		new_branch_name = new_branch_name .. (i > 1 and "-" or "") .. part
	end

	return new_branch_name .. "..."
end

return lualine_util
