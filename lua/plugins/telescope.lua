return {
	"nvim-telescope/telescope.nvim",
	branch = "master",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		local builtin = require("telescope.builtin")
		local project_root = require("util.relative_path").project_root

        local function telescope_opts()
            return {
                cwd = project_root(),
                hidden = true,
            }
        end

		vim.keymap.set("n", "<leader>ff", function()
			builtin.find_files(telescope_opts())
		end, {
			desc = "Find files",
		})

		vim.keymap.set("n", "<leader>fg", function()
			builtin.live_grep(telescope_opts())
		end, {
			desc = "Live grep",
		})

		vim.keymap.set("n", "<leader>fb", builtin.buffers, {
			desc = "Find buffers",
		})

		vim.keymap.set("n", "<leader>fh", builtin.help_tags, {
			desc = "Help tags",
		})
	end,
}
