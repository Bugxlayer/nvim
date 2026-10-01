return {
    dir = vim.fn.stdpath("config") .. "/local/focus.nvim",
    name = "focus.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        require("focus").setup({
            transparent = true,
        })
    end,
}
