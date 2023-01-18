local utils = require("user.utils.util")
utils:set_use_xpcall(true)
require "user.packer"
--require "user.impatient"
require "user.keymap"
require "user.options"
if vim.g.vscode then
  -- VSCode extension
  require "user.vscode"
else
  require "user.alpha"
  require "user.integrations"
  require "user.languages"
end





