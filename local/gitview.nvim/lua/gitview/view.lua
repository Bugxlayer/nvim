local config = require("gitview.config")
local diff = require("gitview.diff")
local files = require("gitview.files")
local git = require("gitview.git")
local state = require("gitview.state")
local status = require("gitview.status")
local util = require("gitview.util")

local M = {}

local autocmd_group = "GitView"

function M.save_layout()
  local tabpage = vim.api.nvim_get_current_tabpage()
  local wins = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    wins[#wins + 1] = {
      win = win,
      buf = vim.api.nvim_win_get_buf(win),
      width = vim.api.nvim_win_get_width(win),
      height = vim.api.nvim_win_get_height(win),
      config = vim.api.nvim_win_get_config(win),
    }
  end
  return {
    tabpage = tabpage,
    wins = wins,
    curwin = vim.api.nvim_get_current_win(),
    curbuf = vim.api.nvim_get_current_buf(),
  }
end

function M.restore_layout(snapshot)
  if not snapshot then
    return
  end
  vim.api.nvim_set_current_tabpage(snapshot.tabpage)

  local tabpage = snapshot.tabpage
  local current_wins = vim.api.nvim_tabpage_list_wins(tabpage)

  -- Close extra gitview windows beyond snapshot count
  while #current_wins > #snapshot.wins do
    local win = current_wins[#current_wins]
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    current_wins = vim.api.nvim_tabpage_list_wins(tabpage)
  end

  -- Reopen windows if we closed too many (unlikely)
  while #current_wins < #snapshot.wins do
    vim.cmd("vsplit")
    current_wins = vim.api.nvim_tabpage_list_wins(tabpage)
  end

  current_wins = vim.api.nvim_tabpage_list_wins(tabpage)
  for i, info in ipairs(snapshot.wins) do
    local win = current_wins[i]
    if win and vim.api.nvim_win_is_valid(win) then
      if vim.api.nvim_buf_is_valid(info.buf) then
        vim.api.nvim_win_set_buf(win, info.buf)
      end
      vim.api.nvim_win_set_width(win, info.width)
      vim.api.nvim_win_set_height(win, info.height)
    end
  end

  if vim.api.nvim_win_is_valid(snapshot.curwin) then
    vim.api.nvim_set_current_win(snapshot.curwin)
  end
end

function M.create_layout(session)
  local cfg = config.get()
  if cfg.layout.open_in == "tab" then
    vim.cmd("tabnew")
    session.tabpage = vim.api.nvim_get_current_tabpage()
  end

  local win = vim.api.nvim_get_current_win()
  vim.cmd("vsplit")
  vim.cmd("vsplit")

  local wins = vim.api.nvim_tabpage_list_wins(session.tabpage)
  session.win_files = wins[1]
  session.win_old = wins[2]
  session.win_new = wins[3]

  local w1, w2, w3 = util.column_widths(cfg.layout.columns)
  vim.api.nvim_win_set_width(session.win_files, w1)
  vim.api.nvim_win_set_width(session.win_old, w2)
  vim.api.nvim_win_set_width(session.win_new, w3)

  files.ensure_buf(session)
  files.ensure_diff_bufs(session)

  vim.api.nvim_win_set_buf(session.win_files, session.buf_files)
  vim.api.nvim_win_set_buf(session.win_old, session.buf_old)
  vim.api.nvim_win_set_buf(session.win_new, session.buf_new)

  vim.api.nvim_set_option_value(
    "statusline",
    "%#StatusLine# GIT FILES %=%#StatusLineNC# %l/%L",
    { win = session.win_files }
  )
  vim.api.nvim_set_option_value("statusline", "%#StatusLine# Last commit", { win = session.win_old })
  vim.api.nvim_set_option_value("statusline", "%#StatusLine# Current", { win = session.win_new })

  vim.api.nvim_set_current_win(session.win_files)
end

function M.setup_autocmds(on_refresh)
  local cfg = config.get()
  local group = vim.api.nvim_create_augroup(autocmd_group, { clear = true })

  if cfg.auto_refresh then
    vim.api.nvim_create_autocmd({ "FocusGained", "ShellCmdPost" }, {
      group = group,
      callback = function()
        if state.is_open() then
          on_refresh()
        end
      end,
    })
  end
end

function M.clear_autocmds()
  pcall(vim.api.nvim_del_augroup_by_name, autocmd_group)
end

function M.refresh(callback)
  local session = state.get()
  if not session or session.closed or not session.repo then
    return
  end

  local gen = state.bump_refresh()

  git.status_async(session.repo, function(stdout, err)
    if session.closed or session.refresh_gen ~= gen then
      return
    end
    if err then
      vim.notify("gitview: " .. err, vim.log.levels.ERROR, { title = "gitview" })
      if callback then
        callback(false)
      end
      return
    end

    session.entries = status.parse_v2(stdout or "")
    files.render(session, files.header_lines(session))

    git.current_branch_async(session.repo, function(branch)
      if session.refresh_gen ~= gen or session.closed then
        return
      end
      session.branch = branch or ""
      git.ahead_behind_async(session.repo, function(ahead, behind)
        if session.refresh_gen ~= gen or session.closed then
          return
        end
        session.ahead = ahead or 0
        session.behind = behind or 0
        files.render(session, files.header_lines(session))

        if session.selected_index < 1 and #session.flat > 0 then
          local entry = files.select_index(session, 1)
          if entry then
            local load_gen = state.bump_load()
            diff.update(entry, load_gen)
          end
        elseif session.selected_id then
          for i, e in ipairs(session.flat) do
            if e.id == session.selected_id then
              session.selected_index = i
              files.move_cursor_to_entry(session)
              local load_gen = state.bump_load()
              diff.update(e, load_gen)
              break
            end
          end
        end

        if callback then
          callback(true)
        end
      end)
    end)
  end)
end

function M.select_entry(entry)
  local session = state.get()
  if not session or not entry then
    return
  end
  local load_gen = state.bump_load()
  diff.update(entry, load_gen)
end

function M.close_buffers(session)
  for _, buf in ipairs({ session.buf_files, session.buf_old, session.buf_new }) do
    if buf and vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

return M
