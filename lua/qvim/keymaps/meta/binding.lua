---@class binding
local binding = {}

local Log = require("qvim.integrations.log")
local default = require("qvim.keymaps.default")
local fn_t = require("qvim.utils.fn_t")

---@class util
local util = nil

---initializes the binding module with the util factory
---@param _util util
---@return binding
function binding.init(_util)
    util = _util
    return binding
end

--- The meta table that maps an index function to retrieve
--- the default keymap options. It implements an `__eq` meta method
--- to allow comparing of right hand side bindings.
binding.mt = {
    ---Merges default options with user defined options stored in the table
    ---@param t table the indexed table
    ---@param opt string
    ---@return boolean|string|integer|function|nil
    __index = function(t, opt)
        if default.valid_keymap_opts[opt] then
            return fn_t.rawget_debug(t, opt) or default.keymap_opts[opt]
        else
            Log:error(string.format("Invalid option '%s' for keymap.", opt))
            return nil
        end
    end,
    ---Set an value for a supported option and fill with defaults
    ---@param t table
    ---@param opt string
    ---@param setting function|boolean|string|integer|nil
    __newindex = function(t, opt, setting)
        if default.valid_keymap_opts[opt] then
            if type(setting) == "function" then
                fn_t.rawset_debug(t, opt, setting)
            elseif (type(setting) == type(default.keymap_opts[opt])) then
                fn_t.rawset_debug(t, opt, setting or default.keymap_opts[opt])
            end
        else
            Log:error(string.format("Invalid option '%s' for keymap.", opt))
        end
    end,
    ---Checks for equality in keymappings. Two keymaps with a different buffer value are not considered equal.
    ---@param t1 table
    ---@param t2 table
    ---@return boolean
    __eq = function(t1, t2)
        if t1.buffer and t2.buffer and t1.buffer ~= t2.buffer then
            return false
        end
        local function is_function(v) return type(v) == "function" end
        for k, v in pairs(t1) do
            if not is_function(v) and t2[k] ~= v then
                return false
            end
        end
        for k, v in pairs(t2) do
            if not is_function(v) and t1[k] ~= v then
                return false
            end
        end
        return true
    end,
    ---An add operation on two mappings of opts_mt returns the unique mapping or both mappings when neither of them are unique.
    ---This may convert the meta table into opts_collection_mt when none of the parsed mappings are unique.
    ---@param t1 any
    ---@param t2 any
    ---@return table|nil
    __add = function(t1, t2)
        return util.truly_unique_mapping(t1, t2) or {}
    end,
    __tostring = function(t)
        return string.format(
            "%s::%s::%s::%s::%s::%s::%s::%s",
            "mode=" .. t.mode,
            "noremap=" .. tostring(t.noremap),
            "nowait=" .. tostring(t.nowait),
            "silent=" .. tostring(t.silent),
            "script=" .. tostring(t.script),
            "expr=" .. tostring(t.expr),
            "unique=" .. tostring(t.unique),
            "buffer=" .. tostring(t.buffer)
        )
    end
}

return binding
