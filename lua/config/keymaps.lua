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

-- <C-/> toggles terminal 1; this opens an additional terminal each time
local term_count = 1
local function new_terminal()
  term_count = term_count + 1
  Snacks.terminal.open(nil, { cwd = LazyVim.root(), count = term_count })
end

-- Ctrl+Shift+/ only arrives when the terminal emits CSI-u (see Windows Terminal
-- settings.json: sendInput "\u001b[47;6u"); Alt+/ works everywhere
for _, lhs in ipairs({ "<C-S-/>", "<M-/>" }) do
  vim.keymap.set({ "n", "t" }, lhs, new_terminal, { desc = "New Terminal (Root Dir)" })
end
vim.keymap.set("n", "<leader>fn", new_terminal, { desc = "New Terminal (Root Dir)" })

vim.keymap.set("n", "<leader>yp", function()
  local path = vim.fn.expand("%:p")
  if path == "" then
    return vim.notify("No file path", vim.log.levels.WARN)
  end
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path, vim.log.levels.INFO, { title = "File path" })
end, { desc = "Copy File Path" })
