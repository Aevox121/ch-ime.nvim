# ch-ime.nvim

Auto-switch input method for Chinese writing in Neovim (LazyVim-friendly).

MVP scope:
- Windows + macOS (Linux needs other tools; see notes)
- Can auto-download `im-select` per platform (recommended)
- Insert mode -> Chinese (`2052`)
- Normal mode -> English (`1033`)
- Terminal Normal mode -> English (`1033`)
- Toggleable (default disabled)
- Statusline shows feature on/off

## Requirements

- Neovim 0.10+
- Windows or macOS
- Either:
  - let `ch-ime` download `im-select` automatically (recommended), or
  - install `im-select` yourself and ensure it is in `PATH`

Upstream tool: https://github.com/daipeihust/im-select

## Installation (LazyVim)

Example plugin spec:

```lua
{
  "yourname/ch-ime.nvim",
  main = "ch-ime",
  -- Default lazy-load: load on keys/commands
  cmd = {
    "ChImeToggle",
    "ChImeEnable",
    "ChImeDisable",
    "ChImeInstall",
    "ChImeDetect",
    "ChImeStatus",
  },
  opts = {
    enabled = false,
    enable_terminal = true,
    im_select = "auto", -- auto download per platform
    -- Per-platform table (recommended for multi-machine users). A plain
    -- string also works if every platform uses the same key.
    normal_im = { windows = "1033", macos = "com.apple.keylayout.ABC" },
    insert_im = { windows = "2052", macos = "com.apple.inputmethod.SCIM.ITABC" },
    install = { on_startup = true },
  },
  keys = {
    {
      "<leader>ui",
      function()
        require("ch-ime").toggle()
      end,
      desc = "Toggle ChIme",
    },
  },
}
```

If you want `im-select` to be downloaded right after startup (without pressing keys first), add:

```lua
event = "VeryLazy"
```

## Lualine

Add `require("ch-ime").statusline` as a component:

```lua
-- inside your lualine sections
{
  function()
    local ok, m = pcall(require, "ch-ime")
    return ok and m.statusline() or "IME-"
  end,
}
```

## Commands

- `:ChImeToggle`
- `:ChImeEnable`
- `:ChImeDisable`
- `:ChImeInstall` (download im-select if `im_select = "auto"`)
- `:ChImeDetect` (print current locale from im-select)
- `:ChImeStatus` (print enabled + im-select cmd + current locale)

## Configuration

Defaults:

```lua
{
  enabled = false,
  im_select = "auto", -- download into stdpath("data")/ch-ime/bin
  -- or "im-select.exe" / "im-select" (use PATH)
  -- or a relative path like "bin/im-select.exe" (relative to plugin root)
  -- or a table like {"bash", "-lc", "im-select.exe"}
  -- string (same key on every platform) OR per-platform table
  --   { windows = ..., macos = ..., linux = ... }
  normal_im = { windows = "1033", macos = "com.apple.keylayout.ABC" },
  insert_im = { windows = "2052", macos = "com.apple.inputmethod.SCIM.ITABC" },
  debounce_ms = 50,
  timeout_ms = 500,
  install = { enabled = true, on_startup = true, dir = nil },
  enable_terminal = true,
  exclude_buftype = { "prompt", "nofile" },
  exclude_filetypes = { "TelescopePrompt" },
  statusline = { enabled = "IME+", disabled = "IME-" },
}
```

## Troubleshooting

- `im-select` on Windows switches *keyboard locale/layout*, not the IME's internal Chinese/English mode.
  - If you switch between Chinese IMEs (Sogou/Rime/Microsoft Pinyin), `:ChImeDetect` may still always return `2052`.
  - To make Normal-mode switch to English, you must have an English keyboard layout installed (for example `en-US`).
    After switching to that layout (Win+Space), `:ChImeDetect` should show a different value (commonly `1033`).
- If `1033/2052` does not match your machine, run `:ChImeDetect` while you are in your desired English/Chinese layouts and use those values.
- If running Neovim inside a Windows terminal causes issues, try running Neovim in Git Bash and set:

```lua
im_select = { "bash", "-lc", "im-select.exe" }
```

### macOS: finding `normal_im` / `insert_im`

On macOS, `im-select` returns an input method key like `com.apple.keylayout.US`.

- Switch to your desired English input source (e.g. U.S. / ABC), then run `:ChImeDetect` and set that value as `normal_im`.
- Switch to your desired Chinese input source, run `:ChImeDetect` again and set that value as `insert_im`.

Common Chinese IME keys:

| IME | key |
|---|---|
| System Pinyin | `com.apple.inputmethod.SCIM.ITABC` |
| Sogou | `com.sogou.inputmethod.sogou.pinyin` |
| WeChat | `com.tencent.inputmethod.wetype.pinyin` |
| Squirrel (Rime) | `im.rime.inputmethod.Squirrel.Hans` |

If you share one config across Windows and macOS machines, use the per-platform table form:

```lua
insert_im = {
  windows = "2052",
  macos = "com.sogou.inputmethod.sogou.pinyin",
},
```

## Linux Notes

The upstream `im-select` project does not provide a Linux binary because Linux already has CLI tools to switch input methods.
For Linux, you should set `im_select` to a Linux-specific command (ibus/fcitx/xkb-switch). A dedicated Linux adapter is not included in this MVP.
