# Neovim config

Personal Neovim setup built on [lazy.nvim](https://github.com/folke/lazy.nvim). It targets day-to-day editing with a Python-friendly LSP stack, Telescope for navigation, and several Git UIs (including a bundled **gitview.nvim** plugin).

## Requirements

- **Neovim** 0.10+ (recommended)
- **Git** (for lazy.nvim bootstrap and Git plugins)
- **Node.js** (optional; some Mason formatters or tools may need it)
- **ripgrep** (`rg`) — used by Telescope live grep

Format-on-save via [conform.nvim](https://github.com/stevearc/conform.nvim) expects these on your `PATH` (Mason can install some of them):

| Tool | Used for |
|------|----------|
| `ruff` | Python formatting |
| `stylua` | Lua formatting |
| `prettier` | JSON, YAML, Markdown |
| `shfmt` | Shell scripts |

## Installation

1. Back up or rename your existing config if needed.
2. Clone this repo into your Neovim config directory:

   ```bash
   git clone https://github.com/Bugxlayer/nvim.git ~/.config/nvim
   ```

3. Start Neovim. **lazy.nvim** is cloned automatically on first launch; plugins install on startup.
4. Run `:Lazy sync` if you want to force a full install/update.
5. Run `:Mason` and ensure LSP servers and formatters you care about are installed (many are set to auto-install via Mason).

### Python virtualenvs

Pyright picks up a `.venv` in the project root or walks upward from the current file. Place `.venv` at your repo root (or a parent directory) for workspace-aware analysis.

## Layout

```
init.lua              Entry: options, netrw, keymaps, lazy
lua/
  options.lua         Editor defaults (numbers, indent, diagnostics, …)
  keymaps.lua         Global keymaps (leader, windows, yank behavior)
  lazy_init.lua       lazy.nvim bootstrap
  python_env.lua      .venv discovery for Pyright
  config/netrw.lua    Netrw tweaks
  util/               Shared helpers (e.g. relative paths for Telescope)
  plugins/            One file per plugin or plugin group (lazy specs)
local/
  focus.nvim/         Bundled colorscheme (dark, minimal)
  gitview.nvim/       Bundled Git UI (see local/gitview.nvim/README.md)
lazy-lock.json        Pinned plugin commits for reproducible installs
```

## Plugins (overview)

| Area | Plugins |
|------|---------|
| UI | [focus.nvim](local/focus.nvim) (local), [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) |
| Navigation | [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) |
| LSP / completion | [mason.nvim](https://github.com/mason-org/mason.nvim), [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig), [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) |
| Syntax | [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) |
| Formatting | [conform.nvim](https://github.com/stevearc/conform.nvim) |
| Git | [vim-fugitive](https://github.com/tpope/vim-fugitive), [diffview.nvim](https://github.com/sindrets/diffview.nvim), **gitview.nvim** (local) |

Leader key is **Space**.

## Keymaps

Run `:WhichKey` (if you add which-key) or check each plugin file for full descriptions. Highlights:

### General

| Key | Action |
|-----|--------|
| `Space` | Leader |
| `jj` (insert) | Exit insert mode |
| `Ctrl-h/j/k/l` | Move between windows |
| `Ctrl-arrows` | Resize splits |
| `Ctrl-s` | Save |
| `Leader e` | Netrw file explorer (`:Ex`) |
| `Leader cc` | Copy relative file path to system clipboard |

Normal-mode `d` / `c` (and visual `d` / `c` / `p`) use the black hole register so deletes/changes do not overwrite the default yank register.

### Telescope

| Key | Action |
|-----|--------|
| `Leader ff` | Find files (project root, respects `.gitignore`) |
| `Leader fh` | Find all files (including ignored/hidden) |
| `Leader fg` | Live grep in project |
| `Leader fb` | Buffers |

### Git — GitView

| Key | Action |
|-----|--------|
| `Leader gg` | Open GitView |
| `Leader gh` | Close GitView |

### Git — Diffview

| Key | Action |
|-----|--------|
| `Leader gs` | Open Diffview (stage/review) |
| `Leader gt` | Toggle changed-files panel |
| `Leader gf` | Focus changed-files panel |
| `Leader gq` | Close Diffview |

Inside Diffview, `Ctrl-Left` / `Ctrl-Right` resize the file panel.

### Git — Fugitive

| Key | Action |
|-----|--------|
| `Leader gD` | Diff split (horizontal) |
| `Leader gv` | Diff split (vertical) |
| `Leader gb` | Blame |
| `Leader gc` | Commit |
| `Leader gp` | Push |
| `Leader gl` | Pull |

## Local plugins

- **focus.nvim** — Colorscheme with optional transparency; see [local/focus.nvim/README.md](local/focus.nvim/README.md).
- **gitview.nvim** — Three-pane Git status/diff UI using the Git CLI only; see [local/gitview.nvim/README.md](local/gitview.nvim/README.md).

Both are loaded via `dir = …/local/…` in `lua/plugins/`.

## Maintenance

```vim
:Lazy          " Plugin UI
:Lazy sync     " Install/update from lazy-lock.json
:Mason         " LSP servers and tools
:TSUpdate      " Update Tree-sitter parsers
```

After changing plugin specs, commit an updated `lazy-lock.json` so other machines stay in sync.

## License

Plugin licenses live in their respective directories (for example `local/gitview.nvim/LICENSE`). Treat this config as personal unless you add a root license file.
