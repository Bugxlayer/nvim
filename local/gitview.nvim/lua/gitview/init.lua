local config = require("gitview.config")
local diff = require("gitview.diff")
local files = require("gitview.files")
local git = require("gitview.git")
local highlights = require("gitview.highlights")
local hunk = require("gitview.hunk")
local keymaps = require("gitview.keymaps")
local state = require("gitview.state")
local util = require("gitview.util")
local view = require("gitview.view")

local M = {}

local COMPARE_CYCLE = {
  { left = "HEAD", right = "WORKTREE" },
  { left = "HEAD", right = "INDEX" },
  { left = "INDEX", right = "WORKTREE" },
}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "gitview" })
end

local function make_actions()
  return {
    close = function()
      M.close()
    end,
    refresh = function()
      M.refresh()
    end,
    stage = function()
      M.stage_current()
    end,
    unstage = function()
      M.unstage_current()
    end,
    stage_all = function()
      M.stage_all()
    end,
    unstage_all = function()
      M.unstage_all()
    end,
    next_file = function()
      M.select_relative(1)
    end,
    prev_file = function()
      M.select_relative(-1)
    end,
    first_file = function()
      M.select_relative(0, true)
    end,
    last_file = function()
      local session = state.get()
      if session and #session.flat > 0 then
        local entry = files.select_index(session, #session.flat)
        if entry then
          view.select_entry(entry)
        end
      end
    end,
    compare_cycle = function()
      M.cycle_compare()
    end,
    commit = function()
      M.commit()
    end,
    push = function()
      M.push()
    end,
    pull = function()
      M.pull()
    end,
    open_file = function()
      M.open_in_editor()
    end,
    filter = function()
      M.prompt_filter()
    end,
    cursor_down = function()
      local session = state.get()
      if not session then
        return
      end
      local entry = files.next_entry(session, 1)
      if entry then
        view.select_entry(entry)
      end
    end,
    cursor_up = function()
      local session = state.get()
      if not session then
        return
      end
      local entry = files.next_entry(session, -1)
      if entry then
        view.select_entry(entry)
      end
    end,
    select = function()
      local session = state.get()
      if not session then
        return
      end
      local folder = files.folder_on_cursor(session)
      if folder then
        files.toggle_folder(session, folder)
        return
      end
      local entry = files.select_cursor(session)
      if entry then
        view.select_entry(entry)
      end
    end,
    toggle_folder = function()
      local session = state.get()
      if not session then
        return
      end
      local folder = files.folder_on_cursor(session)
      if folder then
        files.toggle_folder(session, folder)
      end
    end,
    stage_hunk = function()
      hunk.stage_hunk_at_cursor()
    end,
    unstage_hunk = function()
      M.unstage_hunk()
    end,
    reset_hunk = function()
      M.reset_hunk()
    end,
  }
end

function M.setup(user_opts)
  config.setup(user_opts)
  highlights.setup()
  local cfg = config.get()
  if cfg.integrations.telescope and pcall(require, "telescope") then
    require("gitview.integrations.telescope")
  end
  if cfg.integrations.lualine then
    require("gitview.integrations.lualine")
  end
end

function M.open(opts)
  opts = opts or {}
  local cfg = config.get()

  if cfg.single_instance and state.is_open() then
    notify("gitview is already open", vim.log.levels.WARN)
    return false
  end

  local start = opts.path or vim.fn.expand("%:p")
  if start == "" then
    start = vim.loop.cwd()
  end

  local repo, err = git.find_root(start)
  if not repo then
    notify(err or "not a git repository", vim.log.levels.ERROR)
    return false
  end

  local session = state.new(repo)
  session.restore = view.save_layout()
  view.create_layout(session)

  local actions = make_actions()
  keymaps.setup_file(session.buf_files, actions)
  keymaps.setup_diff(session.buf_old, actions)
  keymaps.setup_diff(session.buf_new, actions)

  view.setup_autocmds(function()
    M.refresh()
  end)

  diff.setup_scroll_sync()

  vim.api.nvim_exec_autocmds("User", { pattern = "GitViewOpen", modeline = false })

  view.refresh(function()
    if #session.flat == 0 then
      diff.update({
        path = "",
        compare = { left = { kind = "EMPTY" }, right = { kind = "EMPTY" } },
      }, state.bump_load())
    end
  end)

  return true
end

function M.close()
  local session = state.get()
  if not session then
    diff.clear()
    return
  end
  session.closed = true
  view.clear_autocmds()
  diff.clear()
  view.close_buffers(session)
  local snapshot = session.restore
  state.clear()
  view.restore_layout(snapshot)
  vim.api.nvim_exec_autocmds("User", { pattern = "GitViewClose", modeline = false })
end

function M.toggle()
  if state.is_open() then
    M.close()
  else
    M.open()
  end
end

function M.refresh()
  view.refresh()
end

function M.select_relative(delta, first)
  local session = state.get()
  if not session then
    return
  end
  local entry
  if first then
    entry = files.select_index(session, 1)
  else
    entry = files.next_entry(session, delta)
  end
  if entry then
    view.select_entry(entry)
  end
end

function M.stage_current()
  local session = state.get()
  local entry = state.current_entry()
  if not session or not entry or not session.repo then
    return
  end
  local paths = { entry.path }
  git.stage_paths(session.repo, paths, function(ok, err)
    if ok then
      M.refresh()
    else
      notify("stage failed: " .. (err or ""), vim.log.levels.ERROR)
    end
  end)
end

function M.unstage_current()
  local session = state.get()
  local entry = state.current_entry()
  if not session or not entry or not session.repo then
    return
  end
  git.unstage_paths(session.repo, { entry.path }, function(ok, err)
    if ok then
      M.refresh()
    else
      notify("unstage failed: " .. (err or ""), vim.log.levels.ERROR)
    end
  end)
end

function M.stage_all()
  local session = state.get()
  if not session or not session.repo then
    return
  end
  git.stage_all(session.repo, function(ok, err)
    if ok then
      M.refresh()
    else
      notify("stage all failed: " .. (err or ""), vim.log.levels.ERROR)
    end
  end)
end

function M.unstage_all()
  local session = state.get()
  if not session or not session.repo then
    return
  end
  git.unstage_all(session.repo, function(ok, err)
    if ok then
      M.refresh()
    else
      notify("unstage all failed: " .. (err or ""), vim.log.levels.ERROR)
    end
  end)
end

function M.cycle_compare()
  local session = state.get()
  if not session then
    return
  end
  if not config.get().compare.allow_cycle then
    return
  end
  local idx = 1
  if session.compare_override then
    for i, mode in ipairs(COMPARE_CYCLE) do
      if mode.left == session.compare_override.left and mode.right == session.compare_override.right then
        idx = i % #COMPARE_CYCLE + 1
        break
      end
    end
  end
  session.compare_override = COMPARE_CYCLE[idx]
  files.render(session, files.header_lines(session))
  local entry = state.current_entry()
  if entry then
    view.select_entry(entry)
  end
end

function M.commit()
  local session = state.get()
  if not session or not session.repo then
    return
  end
  M.close()
  vim.cmd("Git commit")
end

function M.push()
  local session = state.get()
  if not session or not session.repo then
    return
  end
  git.push_async(session.repo, function(ok, err)
    if ok then
      notify("push complete")
      M.refresh()
    else
      notify("push failed: " .. (err or ""), vim.log.levels.ERROR)
    end
  end)
end

function M.pull()
  local session = state.get()
  if not session or not session.repo then
    return
  end
  git.pull_async(session.repo, function(ok, err)
    if ok then
      notify("pull complete")
      M.refresh()
    else
      notify("pull failed: " .. (err or ""), vim.log.levels.ERROR)
    end
  end)
end

function M.open_in_editor()
  local session = state.get()
  local entry = state.current_entry()
  if not session or not entry or not session.repo then
    return
  end
  local path = util.join_path(session.repo.root, entry.path)
  M.close()
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

function M.prompt_filter()
  local session = state.get()
  if not session then
    return
  end
  vim.ui.input({ prompt = "Filter: ", default = session.filter or "" }, function(input)
    if input == nil then
      return
    end
    session.filter = input ~= "" and input or nil
    files.render(session, files.header_lines(session))
    if #session.flat > 0 then
      local entry = files.select_index(session, 1)
      if entry then
        view.select_entry(entry)
      end
    end
  end)
end

function M.unstage_hunk()
  local session = state.get()
  local entry = state.current_entry()
  if not session or not entry or not session.repo then
    return
  end
  git.diff_unified_async(session.repo, entry.path, true, function(diff_text)
    local hunks = hunk.split_hunks(diff_text or "")
    if #hunks == 0 then
      notify("no staged hunks", vim.log.levels.WARN)
      return
    end
    local idx = math.min(vim.api.nvim_win_get_cursor(session.win_new)[1], #hunks)
    git.apply_hunk_async(session.repo, hunks[math.max(1, idx)], false, function(ok, err)
      if ok then
        git.apply_hunk_async(session.repo, hunks[math.max(1, idx)], true, function(ok2, err2)
          -- reverse: apply reverse patch to index - simplified unstage via checkout
          M.refresh()
        end)
      else
        notify("unstage hunk: " .. (err or ""), vim.log.levels.WARN)
        git.unstage_paths(session.repo, { entry.path }, function()
          M.refresh()
        end)
      end
    end)
  end)
end

function M.reset_hunk()
  local session = state.get()
  local entry = state.current_entry()
  if not session or not entry or not session.repo then
    return
  end
  git.diff_unified_async(session.repo, entry.path, false, function(diff_text)
    local hunks = hunk.split_hunks(diff_text or "")
    if #hunks == 0 then
      return
    end
    local idx = math.max(1, math.min(vim.api.nvim_win_get_cursor(session.win_new)[1], #hunks))
    git.apply_hunk_async(session.repo, hunks[idx], false, function(ok, err)
      if ok then
        M.refresh()
      else
        notify("reset hunk failed: " .. (err or ""), vim.log.levels.ERROR)
      end
    end)
  end)
end

return M
