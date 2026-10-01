# focus.nvim

Dark minimal Neovim colorscheme focused on readable syntax highlighting.

## Installation

### lazy.nvim

```lua
{
  "your-user/focus.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("focus").setup({
      transparent = true,
    })
  end,
}
```

### Manual

Clone into your pack path so `lua/focus/init.lua` is on runtimepath, then:

```vim
colorscheme focus
```

or:

```lua
require("focus").setup()
```

Python `"""docstrings"""` are highlighted like `#` comments (`@string.documentation`), not like string literals.

Includes a [lualine](https://github.com/nvim-lualine/lualine.nvim) theme (`lualine/themes/focus.lua`) with graded grays per section — picked up automatically when `theme = "auto"` and colorscheme is `focus`.

## Configuration

```lua
require("focus").setup({
  transparent = true,
  palette = {
    func = "#61afef",
  },
  overrides = {
    CursorLine = { bg = "#252525" },
  },
})
```

## Publish as a GitHub repo

1. Copy this folder to a new directory (e.g. `focus.nvim`).
2. `git init`, add a LICENSE, push to GitHub.
3. Point lazy.nvim at `"your-user/focus.nvim"` instead of a local `dir`.

While developing locally with lazy.nvim:

```lua
{
  dir = vim.fn.stdpath("config") .. "/local/focus.nvim",
  name = "focus.nvim",
  ...
}
```
