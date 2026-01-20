local M = {}

M._state = {
  enabled = false,
  last_switch_ms = 0,
  notified = {},
  tool_ok = nil,
}

---@param opts table
function M.init(opts)
  M._state.enabled = not not opts.enabled
  M._state.last_switch_ms = 0
  M._state.notified = {}
  M._state.tool_ok = nil
end

---@return boolean
function M.enabled()
  return M._state.enabled
end

---@param value boolean
function M.set_enabled(value)
  M._state.enabled = not not value
end

---@return boolean
function M.toggle_enabled()
  M._state.enabled = not M._state.enabled
  return M._state.enabled
end

return M
