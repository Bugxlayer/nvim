local config = require("gitview.config")
local git = require("gitview.git")
local highlights = require("gitview.highlights")
local state = require("gitview.state")
local util = require("gitview.util")

local M = {}

local EMPTY_MSG = "(no tracked version)"
local MISSING_WT = "(not in working tree)"
local BINARY_MSG = "Binary file — not shown"

local saved_scrollopt = nil
local saved_diffopt = nil
local saved_fillchars = nil
local scroll_sync_group = "GitViewScrollSync"
local in_syncbind = false

local function use_clean_diff()
  if config.get().layout.diff_filler then
    return
  end
  if saved_diffopt == nil then
    saved_diffopt = vim.o.diffopt
  end
  if saved_fillchars == nil then
    saved_fillchars = vim.o.fillchars
  end

  -- Drop filler (no "--------" rows); keep linematch / inline / other user diffopt.
  local parts = vim.split(saved_diffopt, ",", { plain = true })
  local kept = {}
  for _, part in ipairs(parts) do
    part = part:match("^%s*(.-)%s*$") or part
    if part ~= "" and part ~= "filler" then
      kept[#kept + 1] = part
    end
  end
  local has_linematch = false
  for _, part in ipairs(kept) do
    if part:match("^linematch:") then
      has_linematch = true
      break
    end
  end
  if not has_linematch then
    kept[#kept + 1] = "linematch:40"
  end
  vim.o.diffopt = table.concat(kept, ",")

  local fc = vim.o.fillchars
  if fc:find("diff:") then
    vim.o.fillchars = fc:gsub("diff:%S+", "diff: ")
  else
    vim.o.fillchars = fc == "" and "diff: " or (fc .. ",diff: ")
  end
end

local function restore_diff_globals()
  if saved_diffopt ~= nil then
    vim.o.diffopt = saved_diffopt
    saved_diffopt = nil
  end
  if saved_fillchars ~= nil then
    vim.o.fillchars = saved_fillchars
    saved_fillchars = nil
  end
end

local function set_buf_lines(bufnr, lines)
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
end

---@param winid integer
---@param side "old"|"new"
local function apply_diff_winopts(winid, side)
  if not vim.api.nvim_win_is_valid(winid) then
    return
  end
  vim.api.nvim_set_option_value("diff", true, { win = winid })
  vim.api.nvim_set_option_value("scrollbind", true, { win = winid })
  vim.api.nvim_set_option_value("cursorbind", true, { win = winid })
  vim.api.nvim_set_option_value("foldmethod", "diff", { win = winid })
  vim.api.nvim_set_option_value("foldlevel", 0, { win = winid })
  vim.api.nvim_set_option_value("foldenable", true, { win = winid })
  if saved_scrollopt == nil then
    saved_scrollopt = vim.o.scrollopt
    vim.o.scrollopt = "ver,jump"
  end
  use_clean_diff()
  vim.api.nvim_set_option_value("foldcolumn", "1", { win = winid })
  highlights.apply_diff_winhighlight(winid, side)
end

--- Nudge scrollbind so both diff windows align (see diffview layout:sync_scroll).
local function sync_scrollbind(session)
  if not session then
    return
  end
  local wins = { session.win_old, session.win_new }
  local target = nil
  local max = 0
  for _, win in ipairs(wins) do
    if win and vim.api.nvim_win_is_valid(win) then
      local count = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win))
      if count >= max then
        max = count
        target = win
      end
    end
  end
  if not target then
    return
  end

  apply_diff_winopts(session.win_old, "old")
  apply_diff_winopts(session.win_new, "new")

  for _, win in ipairs(wins) do
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_call(win, function()
        if win == target then
          vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-E><C-Y>", true, true, true))
        end
      end)
    end
  end
end

function M.setup_scroll_sync()
  if M._scroll_sync_setup then
    return
  end
  M._scroll_sync_setup = true
  local group = vim.api.nvim_create_augroup(scroll_sync_group, { clear = true })
  vim.api.nvim_create_autocmd("WinScrolled", {
    group = group,
    callback = function(ev)
      local session = state.get()
      if not session or session.closed then
        return
      end
      local win = tonumber(ev.match)
      if win ~= session.win_old and win ~= session.win_new then
        return
      end
      if in_syncbind then
        return
      end
      in_syncbind = true
      vim.api.nvim_win_call(win, function()
        pcall(vim.cmd, "syncbind")
      end)
      in_syncbind = false
    end,
  })
end

function M.clear_scroll_sync()
  pcall(vim.api.nvim_del_augroup_by_name, scroll_sync_group)
  M._scroll_sync_setup = false
end

local function diffoff_win(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end
  vim.api.nvim_win_call(win, function()
    pcall(vim.cmd, "diffoff!")
    pcall(vim.api.nvim_set_option_value, "scrollbind", false, { win = 0 })
    pcall(vim.api.nvim_set_option_value, "cursorbind", false, { win = 0 })
    pcall(vim.api.nvim_set_option_value, "diff", false, { win = 0 })
  end)
end

--- Stop diff on GitView windows and free Neovim's diff buffer slots (max 8).
local function teardown_diff(session)
  if session then
    diffoff_win(session.win_old)
    diffoff_win(session.win_new)
    diffoff_win(session.win_files)
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.b[buf].gitview_diff or vim.b[buf].gitview then
      diffoff_win(win)
    end
  end

  pcall(vim.cmd, "diffoff!")
end

local function set_filetype(bufnr, path)
  local ft = util.detect_filetype(path) or "git"
  vim.api.nvim_set_option_value("filetype", ft, { buf = bufnr })
end

---@param entry Gitview.FileEntry
---@param gen integer
function M.update(entry, gen)
  local session = state.get()
  if not session or session.closed or not session.repo then
    return
  end

  if not session.buf_old or not session.buf_new then
    return
  end

  teardown_diff(session)

  set_buf_lines(session.buf_old, { "Loading…" })
  set_buf_lines(session.buf_new, { "Loading…" })

  local left = entry.compare.left
  local right = entry.compare.right
  local path_old = entry.path_old

  if session.compare_override then
    left = { kind = session.compare_override.left }
    right = { kind = session.compare_override.right }
  end

  local pending = 2
  local left_content, right_content
  local left_binary, right_binary = false, false
  local left_err, right_err

  local function maybe_finish()
    pending = pending - 1
    if pending > 0 then
      return
    end
    if session.closed or session.load_gen ~= gen then
      return
    end

    if left_binary or right_binary then
      local msg = { BINARY_MSG }
      set_buf_lines(session.buf_old, msg)
      set_buf_lines(session.buf_new, msg)
      vim.api.nvim_set_option_value("filetype", "gitview", { buf = session.buf_old })
      vim.api.nvim_set_option_value("filetype", "gitview", { buf = session.buf_new })
      return
    end

    local function fill_side(rev, content, err, is_left)
      local buf = is_left and session.buf_old or session.buf_new
      if rev.kind == "EMPTY" then
        set_buf_lines(buf, { EMPTY_MSG })
        vim.api.nvim_set_option_value("filetype", "gitview", { buf = buf })
      elseif err then
        set_buf_lines(buf, { err })
        vim.api.nvim_set_option_value("filetype", "gitview", { buf = buf })
      elseif content == nil or content == "" then
        if rev.kind == "WORKTREE" then
          set_buf_lines(buf, { MISSING_WT })
        else
          set_buf_lines(buf, {})
        end
        set_filetype(buf, entry.path)
      else
        local lines = vim.split(content, "\n", { plain = true })
        if content:sub(-1) == "\n" then
          -- keep trailing newline behavior
        elseif #lines > 0 and lines[#lines] == "" then
          table.remove(lines)
        end
        set_buf_lines(buf, lines)
        set_filetype(buf, entry.path)
      end
    end

    fill_side(left, left_content, left_err, true)
    fill_side(right, right_content, right_err, false)

    if vim.api.nvim_win_is_valid(session.win_old) then
      vim.api.nvim_win_set_buf(session.win_old, session.buf_old)
    end
    if vim.api.nvim_win_is_valid(session.win_new) then
      vim.api.nvim_win_set_buf(session.win_new, session.buf_new)
    end

    apply_diff_winopts(session.win_old, "old")
    apply_diff_winopts(session.win_new, "new")

    vim.schedule(function()
      if session.closed or session.load_gen ~= gen then
        return
      end
      if vim.api.nvim_win_is_valid(session.win_old) then
        vim.api.nvim_win_call(session.win_old, function()
          vim.cmd("diffthis")
        end)
      end
      if vim.api.nvim_win_is_valid(session.win_new) then
        vim.api.nvim_win_call(session.win_new, function()
          vim.cmd("diffthis")
        end)
      end
      use_clean_diff()
      vim.cmd("diffupdate")
      highlights.apply_diff()
      apply_diff_winopts(session.win_old, "old")
      apply_diff_winopts(session.win_new, "new")
      sync_scrollbind(session)
    end)

    M.update_statuslines(entry, left, right, path_old)
  end

  git.load_revision_async(session.repo, left, entry.path, path_old, function(content, err, binary)
    if session.load_gen ~= gen then
      return
    end
    left_content, left_err, left_binary = content, err, binary or false
    maybe_finish()
  end)

  git.load_revision_async(session.repo, right, entry.path, path_old, function(content, err, binary)
    if session.load_gen ~= gen then
      return
    end
    right_content, right_err, right_binary = content, err, binary or false
    maybe_finish()
  end)
end

function M.update_statuslines(entry, left, right, path_old)
  local session = state.get()
  if not session then
    return
  end
  local left_label = git.revision_label(left, entry.path, path_old)
  local right_label = git.revision_label(right, entry.path, path_old)

  local function set_stl(winid, title, sub)
    if winid and vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_set_option_value("statusline", string.format("%%#StatusLine# %s %%=%%#StatusLineNC# %s", title, sub), {
        win = winid,
      })
    end
  end

  set_stl(session.win_old, "Last commit", left_label)
  set_stl(session.win_new, "Current", right_label)
end

function M.clear()
  teardown_diff(state.get())
  M.clear_scroll_sync()
  if saved_scrollopt ~= nil then
    vim.o.scrollopt = saved_scrollopt
    saved_scrollopt = nil
  end
  restore_diff_globals()
end

return M
