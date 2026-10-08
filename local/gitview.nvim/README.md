# gitview.nvim

Minimal Neovim Git UI: three real windows (file list, HEAD/old, worktree/new) with native side-by-side diff. Uses the Git CLI only—no Fugitive or Diffview dependency.

## Requirements

- Neovim 0.10+
- Git 2.23+ (for `git restore --staged`)

## Installation (lazy.nvim)

```lua
{
  dir = vim.fn.stdpath("config") .. "/local/gitview.nvim", -- or your fork URL
  cmd = { "GitView", "GitViewClose", "GitViewToggle" },
  keys = {
    { "<leader>gg", "<cmd>GitView<cr>", desc = "Open GitView" },
    { "<leader>gh", "<cmd>GitViewClose<cr>", desc = "Close GitView" },
  },
  config = function()
    require("gitview").setup({})
  end,
}
```

This config uses `<leader>gg` for GitView; Diffview often uses `<leader>gs`.

## Commands

- `:GitView` — open GitView in the current tab
- `:GitViewClose` — close and restore prior layout
- `:GitViewToggle` — toggle

## Layout

| Column | Default width | Content |
|--------|---------------|---------|
| Left | 20% | Grouped file status |
| Middle | 40% | HEAD / old revision |
| Right | 40% | Worktree / new revision |

Resize with normal window commands (`<C-w>`, `:vertical resize`, etc.).

## Keymaps (file pane)

| Key | Action |
|-----|--------|
| `j` / `k` | Move (select file and update diff) |
| `<CR>` | Select file under cursor |
| `gg` / `G` | First / last file |
| `]f` / `[f` | Next / previous file |
| `r` | Refresh |
| `s` / `u` | Stage / unstage file |
| `S` / `U` | Stage all / unstage all |
| `o` | Cycle compare mode (HEAD/WT, HEAD/INDEX, INDEX/WT) |
| `/` | Filter paths |
| `gf` | Open file in normal editor |
| `c` / `P` / `p` | Commit / push / pull |
| `q` / `<Esc>` | Close |

Diff panes: `]c` / `[c` hunks, `hs` / `hu` / `hr` hunk stage / unstage / reset.

## Configuration

```lua
require("gitview").setup({
  layout = { columns = { 20, 40, 40 }, open_in = "current" },
  auto_refresh = false,
  keymaps = { file = { ... }, diff = { ... } },
  integrations = { telescope = true, lualine = true },
  highlights = {
    diff = {
      add = { bg = "#1e3a2f" },
      change = { bg = "#3a3420" },
      delete = { bg = "#3a2020" },
    },
  },
})
```

Diff panes color **add**, **change**, and **delete** only (`GitViewDiffAdd` / `Change` / `Delete` via `winhighlight`).

**Shortcuts:** `<leader>gg` open, `<leader>gh` close.

## Telescope

`:Telescope gitview` (after setup with `integrations.telescope = true`).

## Lualine

```lua
sections = {
  lualine_x = {
    { require("gitview.integrations.lualine").component },
  },
}
```

## Coexistence

Works alongside **vim-fugitive** and **diffview.nvim**. GitView does not replace `:Git` or `:DiffviewOpen`.

## Tests

From the plugin root (with plenary.nvim on rtp):

```bash
nvim --headless -u NORC -c "lua package.path = ..." 
```

Or run `:PlenaryBustedDirectory tests/` from a config that includes this plugin.

## License

MIT
