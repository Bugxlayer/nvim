return {
  {
    dir = vim.fn.stdpath("config") .. "/local/gitview.nvim",
    name = "gitview.nvim",
    cmd = { "GitView", "GitViewClose", "GitViewToggle" },
    keys = {
      {
        "<leader>gg",
        "<cmd>GitView<cr>",
        desc = "Open GitView",
      },
      {
        "<leader>gh",
        "<cmd>GitViewClose<cr>",
        desc = "Close GitView",
      },
    },
    config = function()
      require("gitview").setup({
        auto_refresh = false,
        integrations = {
          telescope = true,
          lualine = true,
        },
      })
    end,
  },
}
