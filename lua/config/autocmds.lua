-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local function apply_transparent_bg()
  if not vim.g.lazyvim_transparent then
    return
  end
  local groups = {
    "Normal",
    "NormalNC",
    "NormalFloat",
    "SignColumn",
    "LineNr",
    "LineNrAbove",
    "LineNrBelow",
    "CursorLine",
    "CursorLineNr",
    "FoldColumn",
    "Folded",
    "EndOfBuffer",
    "MsgArea",
    "ColorColumn",
    "VertSplit",
    "WinSeparator",
    "TabLine",
    "TabLineFill",
    "TabLineSel",
    "Terminal",
    "TelescopeNormal",
    "TelescopeBorder",
    "FloatBorder",
    "Pmenu",
    "PmenuSel",
    "PmenuSbar",
    "PmenuThumb",
  }
  for _, group in ipairs(groups) do
    vim.api.nvim_set_hl(0, group, { bg = "none" })
  end
end

-- lunaperche uses a very light StatusLine; keep the bar readable without changing the colorscheme
local function patch_statusline_hl()
  vim.api.nvim_set_hl(0, "StatusLine", { fg = "#d4d4d4", bg = "#1a1a1a", bold = true })
  vim.api.nvim_set_hl(0, "StatusLineNC", { fg = "#888888", bg = "#1a1a1a" })
  vim.api.nvim_set_hl(0, "StatusLineTerm", { link = "StatusLine" })
  vim.api.nvim_set_hl(0, "StatusLineTermNC", { link = "StatusLineNC" })
end

local function on_colorscheme()
  apply_transparent_bg()
  patch_statusline_hl()
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = on_colorscheme,
})
on_colorscheme()
