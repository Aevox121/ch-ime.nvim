local util = require("ch-ime.util")

local M = {}

---@param opts table
---@return string
local function install_dir(opts)
  if opts.install and type(opts.install.dir) == "string" and opts.install.dir ~= "" then
    return opts.install.dir
  end
  return vim.fs.joinpath(vim.fn.stdpath("data"), "ch-ime")
end

---@param dir string
local function ensure_dir(dir)
  vim.fn.mkdir(dir, "p")
  vim.fn.mkdir(vim.fs.joinpath(dir, "bin"), "p")
end

---@return "windows"|"macos"|"linux"|"other"
local function platform()
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

---@return boolean
local function is_arm64()
  local uname = vim.uv.os_uname()
  return uname and uname.machine == "arm64"
end

---@param cmd string[]
---@param timeout_ms integer
---@return boolean, string|nil
local function run(cmd, timeout_ms)
  local proc = vim.system(cmd, { text = true })
  local res = proc:wait(timeout_ms)
  if not res then
    return false, "command timed out"
  end
  if res.code ~= 0 then
    local err = util.trim(res.stderr)
    if err == "" then
      err = "command failed with code " .. tostring(res.code)
    end
    return false, err
  end
  return true, nil
end

---@param url string
---@param dest string
---@param timeout_ms integer
---@return boolean, string|nil
local function download(url, dest, timeout_ms)
  if vim.fn.executable("curl") == 1 then
    return run({ "curl", "-fsSL", url, "-o", dest }, timeout_ms)
  end

  if platform() == "windows" and vim.fn.executable("powershell") == 1 then
    local ps = ([[$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing -Uri '%s' -OutFile '%s']]):format(url, dest)
    return run({ "powershell", "-NoProfile", "-Command", ps }, timeout_ms)
  end

  return false, "no downloader found (need curl, or powershell on Windows)"
end

---@param p "windows"|"macos"
---@return string[]
local function candidate_urls(p, opts)
  local override = opts.install and opts.install.urls
  if p == "windows" then
    if type(override) == "table" and type(override.windows) == "table" and #override.windows > 0 then
      return override.windows
    end
    -- Prefer x64 if it exists, then fallback to x86.
    return {
      "https://github.com/daipeihust/im-select/raw/master/im-select-win/out/x64/im-select.exe",
      "https://github.com/daipeihust/im-select/raw/master/im-select-win/out/x86/im-select.exe",
      "https://github.com/daipeihust/im-select/raw/master/win/out/x86/im-select.exe",
    }
  end

  -- macos
  if is_arm64() then
    if type(override) == "table" and type(override.macos_apple) == "table" and #override.macos_apple > 0 then
      return override.macos_apple
    end
    return { "https://raw.githubusercontent.com/daipeihust/im-select/master/macOS/out/apple/im-select" }
  end

  if type(override) == "table" and type(override.macos_intel) == "table" and #override.macos_intel > 0 then
    return override.macos_intel
  end
  return { "https://raw.githubusercontent.com/daipeihust/im-select/master/macOS/out/intel/im-select" }
end

---@param p "windows"|"macos"
---@param dest string
---@return boolean
local function validate_binary(p, dest)
  local st = vim.uv.fs_stat(dest)
  if not st or not st.size or st.size < 1024 then
    return false
  end

  local fd = vim.uv.fs_open(dest, "r", 438) -- 0666
  if not fd then
    return false
  end
  local data = vim.uv.fs_read(fd, 4, 0) or ""
  vim.uv.fs_close(fd)

  if p == "windows" then
    return data:sub(1, 2) == "MZ"
  end
  -- macOS Mach-O magic: FE ED FA CF (intel64) / CF FA ED FE etc.
  local b = { data:byte(1, 4) }
  local hex = string.format("%02X%02X%02X%02X", b[1] or 0, b[2] or 0, b[3] or 0, b[4] or 0)
  return hex == "FEEDFACF" or hex == "CFFAEDFE" or hex == "FEEDFACE" or hex == "CEFAEDFE"
end

---@param opts table
---@param state table
---@param notify boolean
---@return string|nil, string|nil
function M.ensure_sync(opts, state, notify)
  if type(opts.im_select) ~= "string" or opts.im_select ~= "auto" then
    return nil, "im_select is not set to 'auto'"
  end
  if not (opts.install and opts.install.enabled) then
    return nil, "auto install disabled (opts.install.enabled=false)"
  end

  local p = platform()
  if p ~= "windows" and p ~= "macos" then
    return nil, "auto install supports Windows/macOS only"
  end

  local dir = install_dir(opts)
  ensure_dir(dir)

  local bin_name = (p == "windows") and "im-select.exe" or "im-select"
  local dest = vim.fs.joinpath(dir, "bin", bin_name)

  if util.exists(dest) and validate_binary(p, dest) then
    return dest, nil
  end

  if notify then
    util.notify("ch-ime: downloading im-select...", vim.log.levels.INFO)
  end

  local last_err
  for _, url in ipairs(candidate_urls(p, opts)) do
    local dl_timeout = (opts.install and opts.install.timeout_ms) or 15000
    local ok, err = download(url, dest, dl_timeout)
    if ok and validate_binary(p, dest) then
      if p ~= "windows" then
        pcall(vim.uv.fs_chmod, dest, 493) -- 0755
      end
      return dest, nil
    end
    last_err = err or ("download failed: " .. url)
  end

  return nil, last_err or "download failed"
end

---@param opts table
---@param state table
function M.ensure_async(opts, state)
  if type(opts.im_select) ~= "string" or opts.im_select ~= "auto" then
    return
  end
  if not (opts.install and opts.install.enabled) then
    return
  end
  if not (opts.install and opts.install.on_startup) and not opts.enabled then
    return
  end

  if state._installing then
    return
  end
  state._installing = true

  vim.schedule(function()
    local path, err = M.ensure_sync(opts, state, false)
    state._installing = false
    if path then
      opts.im_select = path
      state.tool_ok = nil
    elseif err and util.mark_notified(state, "install_fail") then
      util.notify("ch-ime install failed: " .. err, vim.log.levels.WARN)
    end
  end)
end

return M
