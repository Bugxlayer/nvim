local function lsp_leader_keys()
	local builtin = require("telescope.builtin")
	local lsp_refs_opts = { include_current_line = true }

	return {
		{
			"<leader>gd",
			function()
				builtin.lsp_definitions()
			end,
			desc = "LSP: definitions (Telescope)",
		},
		{
			"<leader>gr",
			function()
				builtin.lsp_references(lsp_refs_opts)
			end,
			desc = "LSP: references (Telescope)",
		},
	}
end

return {
	"nvim-telescope/telescope.nvim",
	branch = "master",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	keys = lsp_leader_keys(),
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
					"%.swp$",
					"%.swo$",
					"%.swp/",
					"swap/",
				},
			})
		end

		local swap_ignore = { "%.swp$", "%.swo$", "%.swp/", "swap/" }

		local function all_files_opts()
			return vim.tbl_extend("force", base_opts(), {
				no_ignore = true,
				file_ignore_patterns = swap_ignore,
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

		local lsp_refs_opts = { include_current_line = true }

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("telescope-lsp-attach", { clear = true }),
			callback = function(event)
				local buf = event.buf
				local opts = { buffer = buf, silent = true }

				local function lsp_definitions()
					builtin.lsp_definitions()
				end
				local function lsp_references()
					builtin.lsp_references(lsp_refs_opts)
				end

				vim.keymap.set("n", "gd", lsp_definitions, vim.tbl_extend("force", opts, {
					desc = "LSP: definitions (Telescope)",
				}))
				vim.keymap.set("n", "<leader>gd", lsp_definitions, vim.tbl_extend("force", opts, {
					desc = "LSP: definitions (Telescope)",
				}))
				vim.keymap.set("n", "gr", lsp_references, vim.tbl_extend("force", opts, {
					desc = "LSP: references (Telescope)",
				}))
				vim.keymap.set("n", "<leader>gr", lsp_references, vim.tbl_extend("force", opts, {
					desc = "LSP: references (Telescope)",
				}))
				vim.keymap.set("n", "grr", function()
					builtin.lsp_references(lsp_refs_opts)
				end, vim.tbl_extend("force", opts, { desc = "LSP: references (Telescope)" }))
				vim.keymap.set("n", "grd", builtin.lsp_definitions, vim.tbl_extend("force", opts, {
					desc = "LSP: definitions (Telescope)",
				}))
				vim.keymap.set("n", "gri", builtin.lsp_implementations, vim.tbl_extend("force", opts, {
					desc = "LSP: implementations (Telescope)",
				}))
				vim.keymap.set("n", "grt", builtin.lsp_type_definitions, vim.tbl_extend("force", opts, {
					desc = "LSP: type definitions (Telescope)",
				}))
				vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, {
					desc = "LSP: hover",
				}))
			end,
		})
	end,
}
