local function palette()
    local focus = package.loaded["focus"]
    if focus and focus.palette then
        return focus.palette
    end
    return require("focus.palette")
end

local function theme()
    local c = palette()

    local function bar(fg, bg, extra)
        return vim.tbl_extend("force", { fg = fg, bg = bg }, extra or {})
    end

    local function mode_pill(accent)
        return bar(c.bg, accent, { gui = "bold" })
    end

    -- Section b/c: editor surface tones (powerline needs distinct bgs)
    local section_b = c.cursorln
    local section_c = c.visual

    local body = {
        a = mode_pill(c.mode_normal),
        b = bar(c.variable, section_b),
        c = bar(c.fg, section_c),
    }

    local inactive = {
        a = bar(c.muted, section_b, { gui = "bold" }),
        b = bar(c.muted, section_b),
        c = bar(c.muted, section_c),
    }

    return {
        normal = body,
        insert = { a = mode_pill(c.mode_insert) },
        visual = { a = mode_pill(c.mode_visual) },
        replace = { a = mode_pill(c.mode_replace) },
        command = { a = mode_pill(c.mode_command) },
        terminal = { a = mode_pill(c.property) },
        inactive = inactive,
    }
end

return theme()
