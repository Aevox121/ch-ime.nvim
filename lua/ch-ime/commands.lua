local core = require("ch-ime.core")
local install = require("ch-ime.install")
local util = require("ch-ime.util")

local M = {}

---@param opts table
---@param state table
function M.setup(opts, state)
  vim.api.nvim_create_user_command("ChImeToggle", function()
    state.enabled = not state.enabled
    if state.enabled then
      install.ensure_async(opts, state)
    end
    vim.cmd("redrawstatus")
    util.notify("ch-ime: " .. (state.enabled and "enabled" or "disabled"))
  end, {})

  vim.api.nvim_create_user_command("ChImeEnable", function()
    state.enabled = true
    install.ensure_async(opts, state)
    vim.cmd("redrawstatus")
    util.notify("ch-ime: enabled")
  end, {})

  vim.api.nvim_create_user_command("ChImeDisable", function()
    state.enabled = false
    vim.cmd("redrawstatus")
    util.notify("ch-ime: disabled")
  end, {})

  vim.api.nvim_create_user_command("ChImeDetect", function()
    state.tool_ok = nil
    state.notified = {}

    local installed, inst_err = install.ensure_sync(opts, state, true)
    if installed then
      opts.im_select = installed
    elseif type(opts.im_select) == "string" and opts.im_select == "auto" then
      util.notify("install failed: " .. (inst_err or "unknown error"), vim.log.levels.WARN)
      return
    end

    local st = core.status(opts)
    if st.ok then
      util.notify("current IM locale: " .. st.current)
    else
      util.notify("detect failed: " .. (st.err or "unknown error"), vim.log.levels.WARN)
    end
  end, {})

  vim.api.nvim_create_user_command("ChImeStatus", function()
    state.tool_ok = nil
    state.notified = {}

    local installed, _ = install.ensure_sync(opts, state, false)
    if installed then
      opts.im_select = installed
    end

    local enabled = state.enabled and "true" or "false"
    local im_select
    if type(opts.im_select) == "string" then
      im_select = opts.im_select
    elseif type(opts.im_select) == "table" then
      im_select = table.concat(opts.im_select, " ")
    else
      im_select = "<invalid>"
    end

    local st = core.status(opts)
    local line = "enabled=" .. enabled .. ", im_select=" .. im_select
    if st.ok then
      line = line .. ", current=" .. st.current
      util.notify(line)
    else
      line = line .. ", error=" .. (st.err or "unknown")
      util.notify(line, vim.log.levels.WARN)
    end
  end, {})

  vim.api.nvim_create_user_command("ChImeInstall", function()
    state.tool_ok = nil
    state.notified = {}
    local installed, err = install.ensure_sync(opts, state, true)
    if installed then
      opts.im_select = installed
      util.notify("installed: " .. installed)
    else
      util.notify("install failed: " .. (err or "unknown error"), vim.log.levels.WARN)
    end
  end, {})
end

return M
