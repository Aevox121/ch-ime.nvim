# ch-ime.nvim

中文环境写文档时，自动管理输入法（LazyVim 友好）。

- 普通/命令模式：自动切到英文
- 插入模式：自动切到中文
- 终端模式：默认生效（终端 Normal 自动切英文）
- 一键开关：默认关闭（避免打扰原有输入习惯）
- 状态栏提示：`IME+` / `IME-`
- 支持 Windows / macOS，并支持自动下载对应平台的 `im-select`

English doc: `README_EN.md`

## 工作原理

本插件通过调用外部工具 `im-select` 来切换输入源：

- Windows：切换的是“系统键盘布局/语言”（locale），不是搜狗/微软拼音内部的中英模式
- macOS：切换的是输入法 key（例如 `com.apple.keylayout.US`）

因此：

- 在 Windows 上，如果你没有安装英文键盘布局（如 `en-US`），`ChImeDetect` 可能一直显示 `2052`，此时普通模式就无法切回英文。

## 依赖

- Neovim 0.10+
- Windows 或 macOS
- 下载工具：优先使用 `curl`（没有则 Windows 退回 powershell）

`im-select` 上游项目：

- https://github.com/daipeihust/im-select

## 安装（LazyVim / lazy.nvim）

把下面配置放到你的 `lua/plugins/ch-ime.lua`（文件名随意）：

```lua
return {
  {
    "Aevox121/ch-ime.nvim",
    main = "ch-ime",
    -- 默认 lazy-load：按键/命令触发加载
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
      -- 推荐：自动下载对应平台的 im-select 到 nvim-data
      im_select = "auto",
      install = { on_startup = true },

      -- Windows 默认 locale（常见情况可直接用）
      normal_im = "1033", -- English (US)
      insert_im = "2052", -- Chinese (PRC)
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
  },

  -- 状态栏（lualine）：默认加到 lualine_x
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}

      table.insert(opts.sections.lualine_x, 1, function()
        local ok, m = pcall(require, "ch-ime")
        return ok and m.statusline() or "IME-"
      end)
    end,
  },
}
```

如果你希望“启动后就自动下载/准备好 im-select”，可以额外加上：

```lua
event = "VeryLazy"
```

## 状态栏（lualine）

上面的 LazyVim 一键配置已默认把状态栏组件加到 `lualine_x`。

如果你想手动加到别的 section，可以将下面组件放进任意位置：

```lua
{
  function()
    local ok, m = pcall(require, "ch-ime")
    return ok and m.statusline() or "IME-"
  end,
}
```

显示说明：

- `IME+`：功能开启
- `IME-`：功能关闭

## 命令

- `:ChImeToggle`
- `:ChImeEnable`
- `:ChImeDisable`
- `:ChImeInstall`：当 `im_select = "auto"` 时，手动触发下载/修复
- `:ChImeDetect`：输出当前输入源标识（用于校准 normal/insert 的值）
- `:ChImeStatus`：输出当前状态 + im-select 路径 + detect 结果

## 配置项

默认配置（可在 `opts = { ... }` 覆盖）：

终端默认生效，如需排除终端，设置 `enable_terminal = false`。

```lua
{
  enabled = false,

  -- "auto"：自动下载到 stdpath("data")/ch-ime/bin
  -- 或者："im-select" / "im-select.exe"（走 PATH）
  -- 或者：绝对路径 / 相对路径（相对插件根目录，例如 "bin/im-select.exe"）
  im_select = "auto",

  -- Windows：locale
  normal_im = "1033",
  insert_im = "2052",

  debounce_ms = 50,
  timeout_ms = 500,

  install = {
    enabled = true,
    on_startup = true,
    dir = nil,
    timeout_ms = 15000,
    urls = nil, -- 可覆盖下载地址（公司内网/镜像源用）
  },

  enable_terminal = true,
  exclude_buftype = { "prompt", "nofile" },
  exclude_filetypes = { "TelescopePrompt" },

  statusline = {
    enabled = "IME+",
    disabled = "IME-",
  },
}
```

## 常见问题

### Windows：为什么 `ChImeDetect` 一直是 2052？

这是因为你切换的是“中文输入法之间”或“中文输入法内部中英”，系统的键盘布局仍然是中文（2052）。

解决方法：

1) 在系统设置里添加英文键盘布局（例如 English (United States) / US）
2) 用 `Win + Space` 切到英文布局
3) 再运行 `:ChImeDetect`，此时通常会看到 `1033`
4) 把该值设置为 `normal_im`

### macOS：如何设置 `normal_im` / `insert_im`？

macOS 的 `im-select` 输出类似：`com.apple.keylayout.US`

1) 切到英文输入源（例如 U.S.），运行 `:ChImeDetect`，把输出填到 `normal_im`
2) 切到中文输入源，运行 `:ChImeDetect`，把输出填到 `insert_im`

### Windows Terminal / cmd / powershell 下不生效？

`im-select` 在某些 Windows 终端环境下可能存在限制。可以尝试用 Git Bash 执行：

```lua
im_select = { "bash", "-lc", "im-select.exe" }
```

## Linux 说明

上游 `im-select` 不提供 Linux 二进制（Linux 本身有 ibus/fcitx/xkb-switch 等工具）。
本插件暂不内置 Linux adapter；你可以自行把 `im_select` 配成对应命令（后续可扩展）。
