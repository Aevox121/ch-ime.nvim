local core = require("ch-ime.core")

local M = {}

---@param opts table
---@param state table
function M.setup(opts, state)
  local group = vim.api.nvim_create_augroup("ChIme", { clear = true })

  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    callback = function()
      core.switch_to(opts, state, opts.insert_im)
    end,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    callback = function()
      core.switch_to(opts, state, opts.normal_im)
    end,
  })

  vim.api.nvim_create_autocmd("TermEnter", {
    group = group,
    callback = function()
      core.switch_to(opts, state, opts.insert_im)
    end,
  })

  vim.api.nvim_create_autocmd("TermLeave", {
    group = group,
    callback = function()
      core.switch_to(opts, state, opts.normal_im)
    end,
  })

  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    pattern = { "t:*", "*:t" },
    callback = function()
      local ev = vim.v.event or {}
      local bufnr = vim.api.nvim_get_current_buf()
      if vim.bo[bufnr].buftype ~= "terminal" then
        return
      end

      local new_mode = ev.new_mode or ""
      local old_mode = ev.old_mode or ""

      if vim.startswith(new_mode, "t") then
        core.switch_to(opts, state, opts.insert_im)
        return
      end

      if vim.startswith(old_mode, "t") and not vim.startswith(new_mode, "t") then
        core.switch_to(opts, state, opts.normal_im)
      end
    end,
  })
end

return M
