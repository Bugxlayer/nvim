return {
    "stevearc/conform.nvim",

    event = { "BufWritePre" },

    opts = {
        formatters_by_ft = {
            python = { "ruff_format" },
            lua = { "stylua" },
            json = { "prettier" },
            yaml = { "prettier" },
            markdown = { "prettier" },
            sh = { "shfmt" },
            bash = { "shfmt" },
        },

        format_on_save = {
            timeout_ms = 500,
            lsp_fallback = true,
        },
    },
}
