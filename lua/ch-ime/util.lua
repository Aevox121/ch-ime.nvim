local M = {}

---@return integer
function M.now_ms()
  return vim.uv.now()
end

---@param s? string
---@return string
function M.trim(s)
  return vim.trim(s or "")
end

---@param list any
---@param value any
---@return boolean
function M.contains(list, value)
  if type(list) ~= "table" then
    return false
  end
  for _, v in ipairs(list) do
    if v == value then
      return true
    end
  end
  return false
end

---@param base string|table
---@param args string[]
---@return string[]
function M.build_cmd(base, args)
  local cmd
  if type(base) == "string" then
    cmd = { base }
  elseif type(base) == "table" then
    cmd = vim.deepcopy(base)
  else
    cmd = {}
  end
  for _, a in ipairs(args) do
    table.insert(cmd, a)
  end
  return cmd
end

---@return string|nil
function M.plugin_root()
  local hits = vim.api.nvim_get_runtime_file("lua/ch-ime/init.lua", false)
  local init = hits and hits[1] or nil
  if not init then
    return nil
  end

  local dir = vim.fs.dirname(init) -- .../lua/ch-ime
  dir = vim.fs.dirname(dir) -- .../lua
  dir = vim.fs.dirname(dir) -- plugin root
  return dir
end

---@param p string
---@return boolean
function M.is_pathlike(p)
  return p:find("/", 1, true) ~= nil or p:find("\\", 1, true) ~= nil
end

---@param p string
---@return boolean
function M.is_absolute(p)
  -- Unix: /foo
  if p:sub(1, 1) == "/" then
    return true
  end
  -- Windows drive: C:\ or C:/
  if p:match("^%a:[/\\]") then
    return true
  end
  -- UNC: \\server\share
  if p:match("^\\\\") then
    return true
  end
  return false
end

---@param p string
---@return boolean
function M.exists(p)
  return vim.uv.fs_stat(p) ~= nil
end

---@param state table
---@param key string
---@return boolean
function M.mark_notified(state, key)
  state.notified = state.notified or {}
  if state.notified[key] then
    return false
  end
  state.notified[key] = true
  return true
end

---@param msg string
---@param level? integer
function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "ch-ime" })
end

return M
