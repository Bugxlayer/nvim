local hidden_dir = [[\%(^\|[| \t]\)\zs\.\([./]\)\@!\S\+/]]
local hidden_file = [[\%(^\|[| \t]\)\zs\.\([./]\)\@!\S\+\ze[ \t]*$]]

local function apply_netrw_matches(buf)
    if vim.bo[buf].filetype ~= "netrw" then
        return
    end

    if vim.b.netrw_match_ids then
        for _, id in ipairs(vim.b.netrw_match_ids) do
            pcall(vim.fn.matchdelete, id)
        end
    end

    vim.b.netrw_match_ids = {
        vim.fn.matchadd("FocusPathHiddenDir", hidden_dir, 10),
        vim.fn.matchadd("FocusPathHidden", hidden_file, 10),
    }
end

vim.g.netrw_list_hide = 0

vim.api.nvim_create_autocmd("FileType", {
    pattern = "netrw",
    callback = function(args)
        apply_netrw_matches(args.buf)
    end,
})

vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(args)
        if vim.bo[args.buf].filetype == "netrw" then
            apply_netrw_matches(args.buf)
        end
    end,
})
