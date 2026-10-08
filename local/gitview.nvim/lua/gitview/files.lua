local config = require("gitview.config")
local state = require("gitview.state")
local status = require("gitview.status")

local M = {}

function M.ensure_buf(session)
  if session.buf_files and vim.api.nvim_buf_is_valid(session.buf_files) then
    return session.buf_files
  end
  session.buf_files = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(session.buf_files, "gitview://files")
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = session.buf_files })
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = session.buf_files })
  vim.api.nvim_set_option_value("swapfile", false, { buf = session.buf_files })
  vim.api.nvim_set_option_value("filetype", "gitview", { buf = session.buf_files })
  vim.b[session.buf_files].gitview = true
  return session.buf_files
end

function M.ensure_diff_bufs(session)
  if not session.buf_old or not vim.api.nvim_buf_is_valid(session.buf_old) then
    session.buf_old = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = session.buf_old })
    vim.api.nvim_set_option_value("bufhidden", "hide", { buf = session.buf_old })
    vim.api.nvim_set_option_value("swapfile", false, { buf = session.buf_old })
    vim.b[session.buf_old].gitview_diff = true
  end
  if not session.buf_new or not vim.api.nvim_buf_is_valid(session.buf_new) then
    session.buf_new = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = session.buf_new })
    vim.api.nvim_set_option_value("bufhidden", "hide", { buf = session.buf_new })
    vim.api.nvim_set_option_value("swapfile", false, { buf = session.buf_new })
    vim.b[session.buf_new].gitview_diff = true
  end
end

local function apply_filter(entries, filter)
  if not filter or filter == "" then
    return entries
  end
  local lower = filter:lower()
  local out = {}
  for _, e in ipairs(entries) do
    if e.path:lower():find(lower, 1, true) then
      out[#out + 1] = e
    end
  end
  return out
end

function M.render(session, header_lines)
  local cfg = config.get()
  local entries = session.entries
  if session.filter then
    entries = apply_filter(entries, session.filter)
  end
  session.flat = status.sort_and_flatten(entries)

  local lines, line_to_entry, line_to_folder = status.render_lines(
    session.flat,
    cfg.signs,
    session.collapsed,
    cfg.layout.tree
  )
  if header_lines then
    local combined = {}
    for _, l in ipairs(header_lines) do
      combined[#combined + 1] = l
    end
    combined[#combined + 1] = ""
    for _, l in ipairs(lines) do
      combined[#combined + 1] = l
    end
    lines = combined
    local offset = #header_lines + 1
    local adjusted = {}
    local adjusted_folders = {}
    for ln, e in pairs(line_to_entry) do
      adjusted[ln + offset] = e
    end
    for ln, key in pairs(line_to_folder) do
      adjusted_folders[ln + offset] = key
    end
    line_to_entry = adjusted
    line_to_folder = adjusted_folders
  end

  session.line_to_entry = line_to_entry
  session.line_to_folder = line_to_folder

  local buf = M.ensure_buf(session)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  M.highlight_buf(buf, line_to_entry, line_to_folder)
end

function M.highlight_buf(bufnr, line_to_entry, line_to_folder)
  line_to_folder = line_to_folder or {}
  vim.api.nvim_buf_clear_namespace(bufnr, vim.api.nvim_create_namespace("gitview"), 0, -1)
  local ns = vim.api.nvim_create_namespace("gitview_hl")
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    if line_to_entry[i] then
      vim.api.nvim_buf_add_highlight(bufnr, ns, "GitViewFile", i - 1, 0, -1)
    elseif line_to_folder[i] then
      vim.api.nvim_buf_add_highlight(bufnr, ns, "GitViewFolder", i - 1, 0, -1)
    elseif not line:match("^%s") and line ~= "" and line ~= "No changes" and not line:match("^Branch:")
      and not line:match("^Filter:") and not line:match("^Compare:") then
      vim.api.nvim_buf_add_highlight(bufnr, ns, "GitViewSection", i - 1, 0, -1)
    end
  end
end

function M.toggle_folder(session, key)
  if session.collapsed[key] then
    session.collapsed[key] = nil
  else
    session.collapsed[key] = true
  end
  M.render(session, M.header_lines(session))
  M.move_cursor_to_entry(session)
end

function M.folder_on_cursor(session)
  if not session.win_files or not vim.api.nvim_win_is_valid(session.win_files) then
    return nil
  end
  local row = vim.api.nvim_win_get_cursor(session.win_files)[1]
  return session.line_to_folder and session.line_to_folder[row]
end

function M.select_index(session, index)
  if #session.flat == 0 then
    session.selected_index = 0
    session.selected_id = nil
    return nil
  end
  index = math.max(1, math.min(index, #session.flat))
  session.selected_index = index
  session.selected_id = session.flat[index].id
  M.move_cursor_to_entry(session)
  return session.flat[index]
end

function M.move_cursor_to_entry(session)
  if not session.win_files or not vim.api.nvim_win_is_valid(session.win_files) then
    return
  end
  local target_line = nil
  for ln, e in pairs(session.line_to_entry) do
    if e.id == session.selected_id then
      target_line = ln
      break
    end
  end
  if target_line then
    vim.api.nvim_win_set_cursor(session.win_files, { target_line, 0 })
  end
end

function M.entry_on_cursor(session)
  if not session.win_files or not vim.api.nvim_win_is_valid(session.win_files) then
    return nil
  end
  local row = vim.api.nvim_win_get_cursor(session.win_files)[1]
  return session.line_to_entry[row]
end

function M.select_cursor(session)
  local e = M.entry_on_cursor(session)
  if not e then
    return nil
  end
  for i, fe in ipairs(session.flat) do
    if fe.id == e.id then
      session.selected_index = i
      session.selected_id = e.id
      return e
    end
  end
  return e
end

function M.next_entry(session, delta)
  if #session.flat == 0 then
    return nil
  end
  local idx = session.selected_index
  if idx < 1 then
    idx = 1
  else
    idx = idx + delta
  end
  return M.select_index(session, idx)
end

function M.header_lines(session)
  local parts = {}
  if session.branch and session.branch ~= "" then
    local ab = ""
    if session.ahead > 0 or session.behind > 0 then
      ab = string.format(" ↑%d↓%d", session.ahead, session.behind)
    end
    parts[#parts + 1] = string.format("Branch: %s%s", session.branch, ab)
  end
  if session.filter and session.filter ~= "" then
    parts[#parts + 1] = "Filter: " .. session.filter
  end
  if session.compare_override then
    parts[#parts + 1] = string.format(
      "Compare: %s | %s",
      session.compare_override.left,
      session.compare_override.right
    )
  end
  return parts
end

return M
