local M = {}

---@class Gitview.Session
---@field closed boolean
---@field repo Gitview.Repo|nil
---@field entries Gitview.FileEntry[]
---@field flat Gitview.FileEntry[]
---@field line_to_entry table<number, Gitview.FileEntry>
---@field selected_id string|nil
---@field selected_index integer
---@field win_files integer|nil
---@field win_old integer|nil
---@field win_new integer|nil
---@field buf_files integer|nil
---@field buf_old integer|nil
---@field buf_new integer|nil
---@field tabpage integer|nil
---@field restore table|nil
---@field refresh_gen integer
---@field load_gen integer
---@field branch string|nil
---@field ahead integer
---@field behind integer
---@field compare_override { left: string, right: string }|nil
---@field filter string|nil
---@field collapsed table<string, boolean>
---@field line_to_folder table<number, string>

local session = nil

function M.get()
  return session
end

function M.is_open()
  return session ~= nil and not session.closed
end

function M.new(repo)
  session = {
    closed = false,
    repo = repo,
    entries = {},
    flat = {},
    line_to_entry = {},
    selected_id = nil,
    selected_index = 0,
    win_files = nil,
    win_old = nil,
    win_new = nil,
    buf_files = nil,
    buf_old = nil,
    buf_new = nil,
    tabpage = vim.api.nvim_get_current_tabpage(),
    restore = nil,
    refresh_gen = 0,
    load_gen = 0,
    branch = nil,
    ahead = 0,
    behind = 0,
    compare_override = nil,
    filter = nil,
    collapsed = {},
    line_to_folder = {},
  }
  return session
end

function M.clear()
  session = nil
end

function M.bump_refresh()
  if session then
    session.refresh_gen = session.refresh_gen + 1
    return session.refresh_gen
  end
  return 0
end

function M.bump_load()
  if session then
    session.load_gen = session.load_gen + 1
    return session.load_gen
  end
  return 0
end

function M.find_entry_by_id(id)
  if not session then
    return nil
  end
  for _, e in ipairs(session.flat) do
    if e.id == id then
      return e
    end
  end
  return nil
end

function M.current_entry()
  if not session or session.selected_index < 1 then
    return nil
  end
  return session.flat[session.selected_index]
end

return M
