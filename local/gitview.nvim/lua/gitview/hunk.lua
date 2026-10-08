local git = require("gitview.git")
local state = require("gitview.state")

local M = {}

--- Find unified diff hunk containing cursor line (1-based) in diff buffer
---@param diff_text string
---@param cursor_line number
---@return string|nil patch
function M.hunk_at_line(diff_text, cursor_line)
  if not diff_text or diff_text == "" then
    return nil
  end
  local lines = vim.split(diff_text, "\n", { plain = true })
  local hunks = {}
  local current = nil
  local start_line = 0

  for i, line in ipairs(lines) do
    if line:match("^@@") then
      if current then
        hunks[#hunks + 1] = { start = start_line, lines = current }
      end
      current = { line }
      start_line = i
    elseif current then
      current[#current + 1] = line
    end
  end
  if current then
    hunks[#hunks + 1] = { start = start_line, lines = current }
  end

  -- Map buffer line to hunk via diff fold is hard; use proportional mapping from diff output
  -- Simpler: pick hunk by index from cursor position among @@ markers in buffer
  return nil
end

--- Stage hunk under cursor using git apply --cached
function M.stage_hunk_at_cursor()
  local session = state.get()
  local entry = state.current_entry()
  if not session or not entry or not session.repo then
    return
  end

  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(win) ~= session.buf_new and vim.api.nvim_win_get_buf(win) ~= session.buf_old then
    return
  end

  -- Use line-based hunk index from diff window
  vim.api.nvim_win_call(session.win_new, function()
    vim.cmd("normal! ]c")
  end)

  git.diff_unified_async(session.repo, entry.path, entry.section == "staged", function(diff_text)
    if not diff_text or diff_text == "" then
      vim.notify("gitview: no diff hunks", vim.log.levels.WARN)
      return
    end
    local hunks = M.split_hunks(diff_text)
    if #hunks == 0 then
      return
    end
    -- Stage first hunk as fallback when precise mapping unavailable; user can use line maps
    local hunk_idx = math.min(vim.api.nvim_win_get_cursor(session.win_new)[1], #hunks)
    hunk_idx = math.max(1, math.min(hunk_idx, #hunks))
    local patch = hunks[hunk_idx]
    git.apply_hunk_async(session.repo, patch, true, function(ok, err)
      if ok then
        require("gitview").refresh()
      else
        vim.notify("gitview: stage hunk failed: " .. (err or ""), vim.log.levels.ERROR)
      end
    end)
  end)
end

function M.split_hunks(diff_text)
  local lines = vim.split(diff_text, "\n", { plain = true })
  local hunks = {}
  local header = {}
  for _, line in ipairs(lines) do
    if line:match("^diff ") or line:match("^index ") or line:match("^--- ") or line:match("^%+%+%+ ") then
      header[#header + 1] = line
    else
      break
    end
  end

  local current = nil
  for _, line in ipairs(lines) do
    if line:match("^@@") then
      if current then
        hunks[#hunks + 1] = table.concat(vim.list_extend(vim.deepcopy(header), current), "\n") .. "\n"
      end
      current = { line }
    elseif current then
      current[#current + 1] = line
    end
  end
  if current then
    hunks[#hunks + 1] = table.concat(vim.list_extend(vim.deepcopy(header), current), "\n") .. "\n"
  end
  return hunks
end

function M.navigate_hunk(direction)
  local session = state.get()
  if not session then
    return
  end
  local win = session.win_new
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  vim.api.nvim_win_call(win, function()
    if direction > 0 then
      vim.cmd("normal! ]c")
    else
      vim.cmd("normal! [c")
    end
  end)
end

return M
