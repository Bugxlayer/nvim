---@class focus.Config
---@field transparent? boolean Use transparent editor background
---@field palette? Partial<focus.Palette> Override palette colors
---@field overrides? table<string, vim.api.keyset.highlight> Extra highlight groups

local default_palette = require("focus.palette")
local highlights = require("focus.highlights")

local M = {}

---@type focus.Config
M.defaults = {
    transparent = true,
}

function M.setup(user_opts)
    user_opts = user_opts or {}

    if vim.fn.exists("syntax_on") == 1 then
        vim.cmd.syntax("reset")
    end
    vim.cmd.hi("clear")

    local opts = vim.tbl_deep_extend("force", M.defaults, user_opts)
    local palette = vim.tbl_deep_extend("force", default_palette, opts.palette or {})

    highlights.apply(palette, opts)
    M.palette = palette
    vim.g.colors_name = "focus"
end

return M
