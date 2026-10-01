return {
	"mason-org/mason.nvim",
	dependencies = {
		"mason-org/mason-lspconfig.nvim",
	},
	config = function()
		require("mason").setup()

		require("mason-lspconfig").setup({
			ensure_installed = {
				"pyright",
				"lua_ls",
				"jsonls",
				"yamlls",
				"bashls",
				"stylua",
			},

			automatic_enable = {
				"pyright",
				"lua_ls",
				"jsonls",
				"yamlls",
				"bashls",
				"stylua",
			},
		})
	end,
}
