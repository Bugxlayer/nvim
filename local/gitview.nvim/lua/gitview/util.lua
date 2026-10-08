local M = {}

function M.join_path(root, rel)
  if rel == "" or rel == "." then
    return root
  end
  return root .. "/" .. rel
end

function M.column_widths(cols)
  local total = vim.o.columns
  local w1 = math.max(20, math.floor(total * cols[1] / 100))
  local w2 = math.max(20, math.floor(total * cols[2] / 100))
  local w3 = math.max(20, total - w1 - w2)
  return w1, w2, w3
end

function M.detect_filetype(path)
  local name = vim.fn.fnamemodify(path, ":t")
  local ft = vim.filetype.match({ filename = name, buf = 0 })
  if ft and ft ~= "" then
    return ft
  end
  return vim.filetype.match({ filename = path })
end

function M.truncate(s, max_len)
  if #s <= max_len then
    return s
  end
  return s:sub(1, max_len - 3) .. "..."
end

function M.parse_ahead_behind(stdout)
  if not stdout or stdout == "" then
    return 0, 0
  end
  local ahead, behind = stdout:match("(%d+)%s+(%d+)")
  if ahead and behind then
    return tonumber(ahead), tonumber(behind)
  end
  ahead = stdout:match("(%d+)")
  if ahead then
    return tonumber(ahead), 0
  end
  behind = stdout:match("%s(%d+)$")
  if behind then
    return 0, tonumber(behind)
  end
  return 0, 0
end

return M
