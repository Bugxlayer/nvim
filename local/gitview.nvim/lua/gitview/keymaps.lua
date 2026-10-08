local config = require("gitview.config")
local hunk = require("gitview.hunk")

local M = {}

local function map(mode, lhs, rhs, opts, bufnr)
  if not lhs or lhs == "" then
    return
  end
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { buffer = bufnr, silent = true }, opts or {}))
end

function M.setup_file(bufnr, actions)
  local km = config.get().keymaps.file

  map("n", km.close, actions.close, { desc = "gitview close" }, bufnr)
  map("n", km.close_alt, actions.close, { desc = "gitview close" }, bufnr)
  map("n", km.refresh, actions.refresh, { desc = "gitview refresh" }, bufnr)
  map("n", km.stage, actions.stage, { desc = "gitview stage file" }, bufnr)
  map("n", km.unstage, actions.unstage, { desc = "gitview unstage file" }, bufnr)
  map("n", km.stage_all, actions.stage_all, { desc = "gitview stage all" }, bufnr)
  map("n", km.unstage_all, actions.unstage_all, { desc = "gitview unstage all" }, bufnr)
  map("n", km.next_file, actions.next_file, { desc = "gitview next file" }, bufnr)
  map("n", km.prev_file, actions.prev_file, { desc = "gitview prev file" }, bufnr)
  map("n", km.first_file, actions.first_file, { desc = "gitview first file" }, bufnr)
  map("n", km.last_file, actions.last_file, { desc = "gitview last file" }, bufnr)
  map("n", km.compare_cycle, actions.compare_cycle, { desc = "gitview cycle compare mode" }, bufnr)
  map("n", km.commit, actions.commit, { desc = "gitview commit" }, bufnr)
  map("n", km.push, actions.push, { desc = "gitview push" }, bufnr)
  map("n", km.pull, actions.pull, { desc = "gitview pull" }, bufnr)
  map("n", km.open_file, actions.open_file, { desc = "gitview open in editor" }, bufnr)
  map("n", km.filter, actions.filter, { desc = "gitview filter" }, bufnr)

  map("n", "j", actions.cursor_down, { desc = "gitview next line" }, bufnr)
  map("n", "k", actions.cursor_up, { desc = "gitview prev line" }, bufnr)
  map("n", "<CR>", actions.select, { desc = "gitview select file / toggle folder" }, bufnr)
  map("n", "-", actions.toggle_folder, { desc = "gitview toggle folder" }, bufnr)
end

function M.setup_diff(bufnr, actions)
  local km = config.get().keymaps.diff

  map("n", km.close, actions.close, { desc = "gitview close" }, bufnr)
  map("n", km.close_alt, actions.close, { desc = "gitview close" }, bufnr)
  map("n", km.next_hunk, function()
    hunk.navigate_hunk(1)
  end, { desc = "gitview next hunk" }, bufnr)
  map("n", km.prev_hunk, function()
    hunk.navigate_hunk(-1)
  end, { desc = "gitview prev hunk" }, bufnr)
  map("n", km.stage_hunk, actions.stage_hunk, { desc = "gitview stage hunk" }, bufnr)
  map("n", km.unstage_hunk, actions.unstage_hunk, { desc = "gitview unstage hunk" }, bufnr)
  map("n", km.reset_hunk, actions.reset_hunk, { desc = "gitview reset hunk" }, bufnr)
end

return M
