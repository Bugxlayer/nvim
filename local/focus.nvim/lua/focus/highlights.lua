local M = {}

---@param palette focus.Palette
---@param opts focus.Config
function M.apply(palette, opts)
    local bg = opts.transparent and "NONE" or palette.bg
    local float_bg = opts.transparent and "NONE" or palette.bg

    local function hl(name, spec)
        vim.api.nvim_set_hl(0, name, spec)
    end

    hl("Normal", { fg = palette.fg, bg = bg })
    hl("NormalNC", { fg = palette.fg, bg = bg })
    hl("NormalFloat", { fg = palette.fg, bg = float_bg })
    hl("CursorLine", { bg = opts.transparent and palette.cursorln or palette.cursorln })
    hl("CursorLineNr", { fg = palette.fg, bold = true })
    hl("LineNr", { fg = palette.muted })
    hl("SignColumn", { bg = "NONE" })
    hl("Folded", { fg = palette.muted, bg = "NONE" })
    hl("Visual", { bg = palette.visual })
    hl("Search", { fg = palette.fg, bg = palette.visual })
    hl("IncSearch", { fg = palette.bg, bg = palette.type })
    hl("MatchParen", { bold = true, fg = palette.fg })
    hl("FloatBorder", { fg = palette.muted })
    hl("VertSplit", { fg = palette.muted })
    hl("WinSeparator", { fg = palette.muted })
    hl("StatusLine", { fg = palette.lualine_fg, bg = palette.lualine_b_bg })
    hl("StatusLineNC", { fg = palette.lualine_inactive_fg, bg = palette.lualine_a_bg })
    hl("TabLine", { fg = palette.muted, bg = "NONE" })
    hl("TabLineFill", { bg = "NONE" })
    hl("TabLineSel", { fg = palette.fg, bg = "NONE", bold = true })

    hl("ErrorMsg", { fg = palette.error })
    hl("WarningMsg", { fg = palette.warning })
    hl("DiffAdd", { fg = palette.string })
    hl("DiffChange", { fg = palette.func })
    hl("DiffDelete", { fg = palette.error })

    hl("DiagnosticError", { fg = palette.error })
    hl("DiagnosticWarn", { fg = palette.warning })
    hl("DiagnosticInfo", { fg = palette.func })
    hl("DiagnosticHint", { fg = palette.property })
    hl("DiagnosticUnderlineError", { undercurl = true, sp = palette.error })
    hl("DiagnosticUnderlineWarn", { undercurl = true, sp = palette.warning })
    hl("DiagnosticUnderlineInfo", { undercurl = true, sp = palette.func })
    hl("DiagnosticUnderlineHint", { undercurl = true, sp = palette.property })

    hl("Comment", { fg = palette.comment, italic = true })
    hl("Function", { fg = palette.func })
    hl("Identifier", { fg = palette.variable })
    hl("Keyword", { fg = palette.keyword })
    hl("Operator", { fg = palette.operator })
    hl("String", { fg = palette.string })
    hl("Number", { fg = palette.number })
    hl("Float", { link = "Number" })
    hl("Type", { fg = palette.type })
    hl("Structure", { link = "Type" })
    hl("Constant", { fg = palette.constant })
    hl("Special", { fg = palette.property })
    hl("Error", { fg = palette.error })
    hl("Directory", { fg = palette.property, bold = true })
    hl("FocusPathFilename", { fg = palette.fg })
    hl("FocusPathHidden", { fg = palette.hidden })
    hl("FocusPathHiddenDir", { fg = palette.hidden, italic = true })
    hl("NetrwDir", { link = "Directory" })
    hl("NetrwPlain", { fg = palette.fg })

    hl("@comment", { fg = palette.comment, italic = true })
    hl("@comment.documentation", { fg = palette.comment, italic = true })
    -- Python """docstrings""" (not # comments)
    hl("@string.documentation", { fg = palette.comment, italic = true })
    hl("@keyword", { fg = palette.keyword })
    hl("@keyword.function", { fg = palette.keyword })
    hl("@keyword.operator", { fg = palette.keyword })
    hl("@keyword.return", { fg = palette.keyword })

    hl("@function", { fg = palette.func })
    hl("@function.builtin", { fg = palette.func, italic = true })
    hl("@function.call", { fg = palette.func })
    hl("@method", { fg = palette.func })
    hl("@constructor", { fg = palette.type })

    hl("@type", { fg = palette.type })
    hl("@type.builtin", { fg = palette.type })
    hl("@type.definition", { fg = palette.type })

    hl("@string", { fg = palette.string })
    hl("@string.escape", { fg = palette.property })
    hl("@string.special", { fg = palette.property })

    hl("@number", { fg = palette.number })
    hl("@float", { fg = palette.number })
    hl("@boolean", { fg = palette.constant })

    hl("@variable", { fg = palette.variable })
    hl("@variable.builtin", { fg = palette.type, italic = true })
    hl("@variable.parameter", { fg = palette.variable })
    hl("@parameter", { fg = palette.variable })

    hl("@property", { fg = palette.property })
    hl("@field", { fg = palette.property })
    hl("@attribute", { fg = palette.property })

    hl("@operator", { fg = palette.operator })
    hl("@punctuation", { fg = palette.muted })
    hl("@punctuation.delimiter", { fg = palette.operator })
    hl("@punctuation.bracket", { fg = palette.muted })

    hl("@constant", { fg = palette.constant })
    hl("@constant.builtin", { fg = palette.constant })
    hl("@constant.macro", { fg = palette.keyword })

    hl("@markup.link", { fg = palette.error, underline = true })
    hl("@markup.heading", { fg = palette.func, bold = true })
    hl("@tag", { fg = palette.type })
    hl("@tag.attribute", { fg = palette.property })

    if opts.overrides then
        for group, spec in pairs(opts.overrides) do
            hl(group, spec)
        end
    end
end

return M
