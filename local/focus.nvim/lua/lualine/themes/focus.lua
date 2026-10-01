local function palette()
    local focus = package.loaded["focus"]
    if focus and focus.palette then
        return focus.palette
    end
    return require("focus.palette")
end

-- Powerline separators need distinct section backgrounds to render; use light
-- gray steps + white text so it reads as a white outline (no syntax colors).
local function theme()
    local c = palette()

    local function bar(fg, bg, extra)
        return vim.tbl_extend("force", { fg = fg, bg = bg }, extra or {})
    end

    local text = c.lualine_fg
    local inactive = c.lualine_inactive_fg

    local body = {
        a = bar(text, c.lualine_a_bg, { gui = "bold" }),
        b = bar(text, c.lualine_b_bg),
        c = bar(text, c.lualine_c_bg),
    }

    local inactive_body = {
        a = bar(inactive, c.lualine_a_bg, { gui = "bold" }),
        b = bar(inactive, c.lualine_b_bg),
        c = bar(inactive, c.lualine_c_bg),
    }

    local command_body = {
        a = bar(text, c.lualine_command_a_bg, { gui = "bold" }),
        b = bar(text, c.lualine_command_b_bg),
        c = bar(text, c.lualine_command_c_bg),
    }

    return {
        normal = body,
        insert = { a = body.a },
        visual = { a = body.a },
        replace = { a = body.a },
        command = command_body,
        terminal = { a = body.a },
        inactive = inactive_body,
    }
end

return theme()
