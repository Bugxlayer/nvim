-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Hide netrw's top banner / quick-help line
vim.g.netrw_banner = 0

-- Python: pyright only (no ruff LSP)
vim.g.lazyvim_python_ruff = "none"

-- No tab bar for open files
vim.o.showtabline = 0

-- Transparent editor (terminal must support transparency too)
vim.g.lazyvim_transparent = true
vim.o.pumblend = 80
