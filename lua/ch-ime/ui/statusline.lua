local M = {}

---@param enabled boolean
---@param opts table
---@return string
function M.render(enabled, opts)
  if enabled then
    return opts.statusline.enabled
  end
  return opts.statusline.disabled
end

return M
