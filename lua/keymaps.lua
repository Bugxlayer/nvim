local map = vim.keymap.set

-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("i", "jj", "<Esc>")

-- Better window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Move left" })
map("n", "<C-j>", "<C-w>j", { desc = "Move down" })
map("n", "<C-k>", "<C-w>k", { desc = "Move up" })
map("n", "<C-l>", "<C-w>l", { desc = "Move right" })

-- Resize windows
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

-- Move selected text
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep cursor centered while jumping
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Delete without overwriting yank
map("n", "d", '"_d')
map("n", "D", '"_D')
map("x", "d", '"_d')
map("x", "D", '"_D')

-- Change without overwriting yank
map("n", "c", '"_c')
map("n", "C", '"_C')
map("x", "c", '"_c')
map("x", "C", '"_C')

-- Delete/change a specific text object without clobbering yank
map("n", "di", '"_di')
map("n", "da", '"_da')
map("n", "ci", '"_ci')
map("n", "ca", '"_ca')

-- Visual paste without overwriting the register
map("x", "p", '"_dP')

vim.keymap.set("n", "<leader>e", vim.cmd.Ex, {
	desc = "File explorer",
})

map("n", "<leader>h", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<leader>l", "<cmd>bnext<cr>", { desc = "Next buffer" })

map("n", "<leader>cc", function()
	local path = require("util.relative_path").get()
	if path == "" or path == "[No Name]" then
		vim.notify("No file path to copy", vim.log.levels.WARN)
		return
	end
	vim.fn.setreg("+", path)
	vim.notify("Copied: " .. path, vim.log.levels.INFO)
end, { desc = "Copy relative file path" })
vim.opt.fillchars = {
	eob = " ",
}
-- Save
vim.keymap.set("n", "<C-s>", "<cmd>write<cr>", {
	desc = "Save",
})

vim.keymap.set("i", "<C-s>", "<Esc><cmd>write<cr>", {
	desc = "Save and exit insert mode",
})
vim.keymap.set("n", "<C-z>", "<Nop>")
vim.keymap.set("i", "<C-z>", "<Nop>")
vim.keymap.set("v", "<C-z>", "<Nop>")
