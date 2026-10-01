return {
	"nvim-telescope/telescope.nvim",
	branch = "master",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		local builtin = require("telescope.builtin")
		local project_root = require("util.relative_path").project_root

		local function base_opts()
			return {
				cwd = project_root(),
				hidden = true,
			}
		end

		local function project_files_opts()
			return vim.tbl_extend("force", base_opts(), {
				no_ignore = false,
				file_ignore_patterns = {
					"%.git/",
					"%.git$",
				},
			})
		end

		local function all_files_opts()
			return vim.tbl_extend("force", base_opts(), {
				no_ignore = true,
				file_ignore_patterns = {},
			})
		end

		vim.keymap.set("n", "<leader>ff", function()
			builtin.find_files(project_files_opts())
		end, {
			desc = "Find project files",
		})

		vim.keymap.set("n", "<leader>fh", function()
			builtin.find_files(all_files_opts())
		end, {
			desc = "Find all files (git, ignored, hidden)",
		})

		vim.keymap.set("n", "<leader>fg", function()
			builtin.live_grep(project_files_opts())
		end, {
			desc = "Live grep",
		})

		vim.keymap.set("n", "<leader>fb", builtin.buffers, {
			desc = "Find buffers",
		})
	end,
}
