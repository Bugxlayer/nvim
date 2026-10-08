return {
	{
		"tpope/vim-fugitive",

		cmd = {
			"Git",
			"Gdiffsplit",
			"Gvdiffsplit",
			"Gread",
			"Gwrite",
			"Ggrep",
			"Glgrep",
		},

		keys = {
			{
				"<leader>gD",
				"<cmd>Gdiffsplit<cr>",
				desc = "Fugitive diff (horizontal split)",
			},
			{
				"<leader>gv",
				"<cmd>Gvdiffsplit<cr>",
				desc = "Fugitive diff (vertical split)",
			},
			{
				"<leader>gb",
				"<cmd>Git blame<cr>",
				desc = "Git blame",
			},
			{
				"<leader>gc",
				"<cmd>Git commit<cr>",
				desc = "Git commit",
			},
			{
				"<leader>gp",
				"<cmd>Git push<cr>",
				desc = "Git push",
			},
			{
				"<leader>gl",
				"<cmd>Git pull<cr>",
				desc = "Git pull",
			},
		},
	},
}
