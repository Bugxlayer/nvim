local function toggle_fugitive_summary()
	local function is_status_win(win)
		local buf = vim.api.nvim_win_get_buf(win)
		return vim.bo[buf].filetype == "fugitive"
	end

	local status_wins = vim.tbl_filter(is_status_win, vim.api.nvim_tabpage_list_wins(0))

	if #status_wins > 0 then
		local cur = vim.api.nvim_get_current_win()
		if #status_wins == 1 and status_wins[1] == cur and #vim.api.nvim_tabpage_list_wins(0) == 1 then
			vim.cmd("bdelete")
			return
		end

		for _, win in ipairs(status_wins) do
			pcall(vim.api.nvim_win_close, win, true)
		end
		return
	end

	vim.cmd("Git")
end

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
				"<leader>gg",
				toggle_fugitive_summary,
				desc = "Toggle git status summary (fugitive)",
			},
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
