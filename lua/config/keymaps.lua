-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "ii", "<Esc>", { desc = "Exit insert mode" })

local function netrw_explore(dir)
  vim.cmd("Explore " .. vim.fn.fnameescape(vim.fs.normalize(dir)))
end

vim.keymap.set("n", "<leader>e", function()
  netrw_explore(LazyVim.root())
end, { desc = "Explorer Netrw (root dir)" })

vim.keymap.set("n", "<leader>E", function()
  netrw_explore(vim.uv.cwd())
end, { desc = "Explorer Netrw (cwd)" })

vim.keymap.set("n", "<leader>fe", "<leader>e", { desc = "Explorer Netrw (root dir)", remap = true })
vim.keymap.set("n", "<leader>fE", "<leader>E", { desc = "Explorer Netrw (cwd)", remap = true })

vim.keymap.set("n", "<leader>yp", function()
  local path = vim.fn.expand("%:p")
  if path == "" then
    return vim.notify("No file path", vim.log.levels.WARN)
  end
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path, vim.log.levels.INFO, { title = "File path" })
end, { desc = "Copy File Path" })
