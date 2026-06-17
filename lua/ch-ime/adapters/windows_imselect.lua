local util = require("ch-ime.util")

local M = {}

---@param opts table
---@return boolean
function M.available(opts)
  local cmd = util.build_cmd(opts.im_select, {})
  if #cmd == 0 then
    return false
  end

  local proc = vim.system(cmd, { text = true })
  local res = proc:wait(opts.timeout_ms)
  if not res then
    return false
  end
  return res.code == 0
end

---@param opts table
---@return string|nil, string|nil
function M.get(opts)
  local cmd = util.build_cmd(opts.im_select, {})
  local proc = vim.system(cmd, { text = true })
  local res = proc:wait(opts.timeout_ms)
  if not res then
    return nil, "im-select timed out"
  end
  if res.code ~= 0 then
    local err = util.trim(res.stderr)
    if err == "" then
      err = "im-select failed with code " .. tostring(res.code)
    end
    return nil, err
  end
  return util.trim(res.stdout), nil
end

---@param opts table
---@param locale string
---@return boolean, string|nil
function M.set(opts, locale)
  local cmd = util.build_cmd(opts.im_select, { tostring(locale) })
  -- Fire-and-forget: a sync :wait() blocks the UI thread for the duration of
  -- the im-select.exe spawn (30–200ms cold). With InsertEnter / InsertLeave /
  -- TermEnter / TermLeave / FocusGained / FocusLost all routing through here,
  -- that wait was the dominant source of UI lag on every mode/window switch.
  vim.system(cmd, { text = true })
  return true, nil
end

return M
