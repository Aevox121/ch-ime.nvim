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
---@param imkey string
---@return boolean, string|nil
function M.set(opts, imkey)
  local cmd = util.build_cmd(opts.im_select, { tostring(imkey) })
  local proc = vim.system(cmd, { text = true })
  local res = proc:wait(opts.timeout_ms)
  if not res then
    return false, "im-select timed out (key=" .. tostring(imkey) .. ")"
  end
  if res.code ~= 0 then
    local err = util.trim(res.stderr)
    if err == "" then
      -- macOS im-select exits non-zero without stderr when the input source
      -- id is not enabled in the system. Surface the key so users can fix
      -- their config or enable the source in System Settings > Keyboard.
      err = "im-select failed with code " .. tostring(res.code)
        .. " (key=" .. tostring(imkey) .. ", likely not enabled in System Settings > Keyboard)"
    end
    return false, err
  end
  return true, nil
end

return M
