---The telescope configuration file
local M = {}

local Log = require "qvim.integrations.log"

---Registers the global configuration scope for telescope
function M:init()
  local telescope = {
    active = true,
    on_config_done = nil,
    keymaps = {
      {
        binding_group = "s",
        name = "Search",
        bindings = {
          b = { rhs = "<cmd>Telescope git_branches<cr>", desc = "Checkout branch" },
          c = { rhs = "<cmd>Telescope colorscheme<cr>", desc = "Colorscheme" },
          h = { rhs = "<cmd>Telescope help_tags<cr>", desc = "Find Help" },
          M = { rhs = "<cmd>Telescope man_pages<cr>", desc = "Man Pages" },
          r = { rhs = "<cmd>Telescope oldfiles<cr>", desc = "Open Recent File" },
          R = { rhs = "<cmd>Telescope registers<cr>", desc = "Registers" },
          k = { rhs = "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
          C = { rhs = "<cmd>Telescope commands<cr>", desc = "Commands" },
        },
        options = {
          prefix = "<leader>"
        }
      }
    },
    options = {
      -- telescope option configuration

    },
  }

  return telescope
end

function M:config()
  require("qvim.integrations.telescope.extensions"):config()

  local _telescope = qvim.integrations.telescope
  local _telescope_extensions = qvim.integrations.telescope.extensions
  _telescope.options.extensions = _telescope_extensions.options.extensions
end

---The telescope setup function. The module will be required by
---this function and it will call the respective setup function.
---A on_config_done function will be called if the plugin implements it.
function M:setup()
  local status_ok, telescope = pcall(reload, "telescope")
  if not status_ok then
    Log:warn(string.format("The plugin '%s' could not be loaded.", telescope))
    return
  end

  local _telescope = qvim.integrations.telescope
  local _telescope_extensions = _telescope.extensions

  telescope.setup(_telescope.options)
  for _, value in ipairs(_telescope_extensions.options.extensions_to_load) do
    -- important to call after telescope setup
    telescope.load_extension(value)
  end

  if _telescope.on_config_done then
    _telescope.on_config_done()
  end
end

return M
