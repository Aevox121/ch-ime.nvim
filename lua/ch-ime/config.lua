local util = require("ch-ime.util")

local M = {}

M.defaults = {
  enabled = false,
  -- Can be a string (executable in PATH) or a list-like table.
  -- Examples:
  --   "im-select.exe"
  --   { "C:/tools/im-select.exe" }
  --   { "bash", "-lc", "im-select.exe" }
  -- "auto" will download a suitable binary (Windows/macOS) into stdpath("data").
  -- You can still set it to a PATH executable ("im-select.exe" / "im-select") or a full path.
  im_select = "auto",
  -- normal_im / insert_im accept either a plain string (same key on every
  -- platform) or a per-platform table: { windows = ..., macos = ..., linux = ... }.
  -- The table form is resolved against the current platform in merge().
  normal_im = { windows = "1033", macos = "com.apple.keylayout.ABC" },
  insert_im = { windows = "2052", macos = "com.apple.inputmethod.SCIM.ITABC" },
  debounce_ms = 50,
  timeout_ms = 500,
  install = {
    enabled = true,
    -- If true, start downloading at setup() time (async).
    -- If false, it will download when you enable the plugin or run :ChImeInstall.
    on_startup = true,
    -- Installation directory (default: stdpath("data") .. "/ch-ime")
    dir = nil,
    -- Download timeout for fetching im-select (ms)
    timeout_ms = 15000,
    -- Optional override download URLs.
    -- {
    --   windows = { "https://.../im-select.exe" },
    --   macos_intel = { "https://.../im-select" },
    --   macos_apple = { "https://.../im-select" },
    -- }
    urls = nil,
  },
  restore_on_focus_lost = true,
  enable_terminal = true,
  exclude_buftype = { "prompt", "nofile" },
  exclude_filetypes = { "TelescopePrompt" },
  statusline = {
    enabled = "IME+",
    disabled = "IME-",
  },
  notify = {
    missing_tool = true,
    exec_fail = true,
  },
}

---@return "windows"|"macos"|"linux"|"other"
local function current_platform()
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    return "windows"
  end
  if vim.fn.has("mac") == 1 then
    return "macos"
  end
  if vim.fn.has("linux") == 1 then
    return "linux"
  end
  return "other"
end

---Resolve a per-platform IM key table to the entry for the current platform.
---String values pass through unchanged (backward compatible).
---@param val any
---@return string|nil
local function resolve_per_platform(val)
  if type(val) ~= "table" then
    return val
  end
  return val[current_platform()]
end

---@param user_opts? table
---@return table
function M.merge(user_opts)
  if user_opts == nil then
    user_opts = {}
  end

  local opts = vim.tbl_deep_extend("force", {}, M.defaults, user_opts)

  opts.normal_im = resolve_per_platform(opts.normal_im)
  opts.insert_im = resolve_per_platform(opts.insert_im)

  if not opts.enable_terminal and not util.contains(opts.exclude_buftype, "terminal") then
    table.insert(opts.exclude_buftype, "terminal")
  end

  -- Allow a shareable relative path like "bin/im-select.exe".
  -- We resolve it against the plugin root if it exists.
  if type(opts.im_select) == "string" and opts.im_select ~= "auto" then
    local s = opts.im_select
    if util.is_pathlike(s) and not util.is_absolute(s) then
      local root = util.plugin_root()
      if root then
        local candidate = vim.fs.joinpath(root, s)
        if util.exists(candidate) then
          opts.im_select = candidate
        end
      end
    end
  end

  return opts
end

return M
