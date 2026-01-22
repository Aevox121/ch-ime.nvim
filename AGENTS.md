# Agent Notes (ch-ime.nvim)

Neovim plugin in Lua (Neovim 0.10+). Uses `vim.system()` and `vim.uv`.
No CI and no automated tests currently.

## Repo Layout

- `lua/ch-ime/init.lua`: public API (`setup`, `toggle`, `enable`, `disable`, `statusline`).
- `lua/ch-ime/config.lua`: defaults + option merge.
- `lua/ch-ime/state.lua`: runtime state (`enabled`, debounce, one-time notifications).
- `lua/ch-ime/core.lua`: adapter selection + switch/detect logic.
- `lua/ch-ime/autocmds.lua`: InsertEnter/InsertLeave hooks.
- `lua/ch-ime/commands.lua`: `:ChIme*` user commands.
- `lua/ch-ime/install.lua`: optional auto-download of upstream `im-select`.
- `lua/ch-ime/adapters/*.lua`: OS-specific wrappers.

## Build / Lint / Test

No build step.

### Smoke Checks (headless Neovim)

```sh
# load + setup
nvim --headless --clean \
  "+set rtp^=." \
  "+lua require('ch-ime').setup({ enabled = false })" \
  "+qa"

# quick behavior check
nvim --headless --clean \
  "+set rtp^=." \
  "+lua local m=require('ch-ime'); m.setup({enabled=false}); m.toggle(); print(m.statusline())" \
  "+qa"
```

### Formatting (optional)

No `stylua.toml` is committed. If you have Stylua:

```sh
stylua lua
```

Style to preserve: 2-space indent, double quotes, trailing commas in multiline tables.

### Lint (optional)

No linter config is committed; keep lint changes minimal and scoped.

```sh
luacheck lua
selene lua
```

### Tests

No `tests/` or `spec/` directory today.

If you add tests, prefer headless Neovim + plenary/busted. In particular, keep a
simple way to run a single file or a single test name:

```sh
# single test file (example)
nvim --headless --clean \
  "+set rtp^=." \
  "+lua require('plenary.test_harness').test_directory('tests/install_spec.lua', { minimal_init = './tests/minimal_init.lua' })" \
  "+qa"

# single test name (example)
nvim --headless --clean \
  "+set rtp^=." \
  "+lua require('plenary.busted').run({ filter = 'downloads binary' })" \
  "+qa"
```

## Code Style

### Module Structure

```lua
local M = {}

function M.some_fn() end

return M
```

Prefer `local function helper()` for non-exported helpers.

### Imports

- Put `require(...)` at the top: `local util = require("ch-ime.util")`.
- Use the plugin namespace (`ch-ime.*`), not relative path hacks.

### Formatting

- 2-space indent; double quotes.
- Avoid very long lines; wrap long tables/argv lists.
- In multiline tables, keep trailing commas.

### Types (LuaLS / EmmyLua)

- Add `---@param` / `---@return` on public functions and non-trivial helpers.
- Use string unions when useful (see `lua/ch-ime/install.lua`).

### Naming

- Files: `snake_case.lua`.
- Locals: `snake_case` (`state_mod`, `statusline_ui`).
- Public API: short verbs (`setup`, `toggle`).

### Error Handling & Notifications

- Prefer `(nil, err)` / `(false, err)` returns; avoid throwing.
- Treat process timeouts as failures (`vim.system(...):wait(timeout)` returning `nil`).
- Trim stderr/stdout with `util.trim()`; provide fallback messages when empty.
- Avoid spamming: gate repeated warnings via `util.mark_notified(state, key)`.

### External Commands / Shell Safety

- Build argv arrays, not shell strings: `util.build_cmd(opts.im_select, args)`.
- Prefer `vim.system(cmd, { text = true })`.
- Keep timeouts configurable (`opts.timeout_ms`, `opts.install.timeout_ms`).

### Paths / Cross-Platform

- Use `vim.fs.joinpath(...)`.
- Accept Windows drive paths + UNC paths (see `lua/ch-ime/util.lua`).
- For lightweight file checks, prefer `vim.uv.fs_stat/fs_open/fs_read/fs_close`.

### Neovim APIs

- Autocmds: dedicated augroup `ChIme`; keep callbacks small.
- Commands: `vim.api.nvim_create_user_command`.
- Shared state lives in `lua/ch-ime/state.lua` (avoid globals).

## Cursor / Copilot Rules

No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md` found.
