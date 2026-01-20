local util = require("ch-ime.util")
local install = require("ch-ime.install")

local windows_imselect = require("ch-ime.adapters.windows_imselect")
local macos_imselect = require("ch-ime.adapters.macos_imselect")

local M = {}

---@param opts table
---@return table|nil, string|nil
function M.get_adapter(opts)
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    return windows_imselect, nil
  end
  if vim.fn.has("mac") == 1 then
    return macos_imselect, nil
  end
  return nil, "ch-ime MVP supports Windows/macOS only"
end

---@param opts table
---@param bufnr integer
---@return boolean
function M.buf_allowed(opts, bufnr)
  local bt = vim.bo[bufnr].buftype
  local ft = vim.bo[bufnr].filetype

  if bt ~= "" and util.contains(opts.exclude_buftype, bt) then
    return false
  end
  if util.contains(opts.exclude_filetypes, ft) then
    return false
  end
  return true
end

---@param opts table
---@param state table
---@return boolean
function M.debounced(opts, state)
  local now = util.now_ms()
  if (now - (state.last_switch_ms or 0)) < (opts.debounce_ms or 0) then
    return true
  end
  state.last_switch_ms = now
  return false
end

---@param opts table
---@param state table
---@param target_locale string
function M.switch_to(opts, state, target_locale)
  if not state.enabled then
    return
  end

  if type(opts.im_select) == "string" and opts.im_select == "auto" then
    local installed, err = install.ensure_sync(opts, state, false)
    if installed then
      opts.im_select = installed
      state.tool_ok = nil
    else
      if opts.notify and opts.notify.missing_tool and util.mark_notified(state, "auto_install_fail") then
        util.notify("ch-ime: im-select not installed: " .. (err or "unknown"), vim.log.levels.WARN)
      end
      return
    end
  end

  local bufnr = vim.api.nvim_get_current_buf()
  if not M.buf_allowed(opts, bufnr) then
    return
  end

  if M.debounced(opts, state) then
    return
  end

  local adapter, adapter_err = M.get_adapter(opts)
  if not adapter then
    if opts.notify and opts.notify.missing_tool and util.mark_notified(state, "no_adapter") then
      util.notify(adapter_err, vim.log.levels.WARN)
    end
    return
  end

  if state.tool_ok == nil then
    state.tool_ok = adapter.available(opts)
  end
  if not state.tool_ok then
    if opts.notify and opts.notify.missing_tool and util.mark_notified(state, "missing_tool") then
      util.notify("im-select not available (check PATH or opts.im_select)", vim.log.levels.WARN)
    end
    return
  end

  local ok, err = adapter.set(opts, target_locale)
  if not ok then
    if opts.notify and opts.notify.exec_fail and util.mark_notified(state, "exec_fail") then
      util.notify("im-select failed: " .. (err or "unknown error"), vim.log.levels.WARN)
    end
  end
end

---@param opts table
---@return table
function M.status(opts)
  local adapter, err = M.get_adapter(opts)
  if not adapter then
    return { ok = false, current = nil, err = err }
  end
  local current, get_err = adapter.get(opts)
  if not current then
    return { ok = false, current = nil, err = get_err }
  end
  return { ok = true, current = current, err = nil }
end

return M
