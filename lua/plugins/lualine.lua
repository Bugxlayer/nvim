local python_env = require("python_env")
return {
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("lualine").setup({
				options = {
					theme = "auto",
					icons_enabled = true,
					component_separators = { left = "", right = "" },
					section_separators = { left = "", right = "" },
					globalstatus = true,
					disabled_filetypes = {
						statusline = {},
						winbar = {},
					},
				},

				sections = {
					lualine_a = {
						{
							"mode",
							fmt = function(str)
								return str:sub(1, 1)
							end,
						},
					},

					lualine_b = {
						{
							"branch",
							icon = "",
						},
					},

					lualine_c = {
						{
							function()
								return require("util.relative_path").get_colored()
							end,
						},
					},
					lualine_x = {
						{
							"filetype",
							icon_only = true,
						},
					},

					lualine_y = {
						{
							function()
								local venv = python_env.get_venv()
								return venv and vim.fn.fnamemodify(venv, ":t") or nil
							end,
							cond = function()
								return python_env.get_venv() ~= nil
							end,
						},
					},

					lualine_z = {
						{
							function()
								return tostring(vim.fn.line("$"))
							end,
						},
					},
				},
			})
		end,
	},
}
