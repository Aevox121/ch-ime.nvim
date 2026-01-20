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
end

return M
