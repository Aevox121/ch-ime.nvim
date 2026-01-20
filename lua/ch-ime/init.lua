local config = require("ch-ime.config")
local state_mod = require("ch-ime.state")
local install = require("ch-ime.install")

local autocmds = require("ch-ime.autocmds")
local commands = require("ch-ime.commands")
local statusline_ui = require("ch-ime.ui.statusline")

local M = {}

M._opts = nil

---@param user_opts? table
function M.setup(user_opts)
  M._opts = config.merge(user_opts)
  state_mod.init(M._opts)

  commands.setup(M._opts, state_mod._state)
  autocmds.setup(M._opts, state_mod._state)

  install.ensure_async(M._opts, state_mod._state)
end

---@return boolean
function M.toggle()
  local enabled = state_mod.toggle_enabled()
  if enabled then
    install.ensure_async(M._opts, state_mod._state)
  end
  vim.cmd("redrawstatus")
  return enabled
end

function M.enable()
  state_mod.set_enabled(true)
  install.ensure_async(M._opts, state_mod._state)
  vim.cmd("redrawstatus")
end

function M.disable()
  state_mod.set_enabled(false)
  vim.cmd("redrawstatus")
end

---@return string
function M.statusline()
  local opts = M._opts or config.defaults
  return statusline_ui.render(state_mod.enabled(), opts)
end

return M
