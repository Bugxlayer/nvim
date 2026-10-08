local M = {}

local SECTION_ORDER = { "changes", "staged", "untracked", "conflicted" }

local function sign_for_xy(x, y, status_override)
  if status_override then
    return status_override
  end
  if x == "?" and y == "?" then
    return "?"
  end
  if x == "U" or y == "U" or x == "A" and y == "A" then
    return "U"
  end
  if y == "D" or (x == " " and y == "D") then
    return "D"
  end
  if x == "D" then
    return "D"
  end
  if x == "A" or y == "A" then
    return "A"
  end
  if x == "R" or y == "R" then
    return "R"
  end
  if x == "C" or y == "C" then
    return "C"
  end
  if x == "M" or y == "M" or x == "T" or y == "T" then
    return "M"
  end
  return "M"
end

--- Default diff: last commit (HEAD) vs current file on disk (worktree).
local function compare_for(section, _x, _y)
  if section == "untracked" then
    return { left = { kind = "EMPTY" }, right = { kind = "WORKTREE" } }
  end
  return { left = { kind = "HEAD" }, right = { kind = "WORKTREE" } }
end

---@param x string
---@param y string
---@return boolean has_staged
---@return boolean has_unstaged
local function is_column_changed(c)
  return c ~= " " and c ~= "?" and c ~= "."
end

local function xy_flags(x, y)
  return is_column_changed(x), is_column_changed(y)
end

---@param entry table
local function add_entry(entries, entry)
  entries[#entries + 1] = entry
end

--- Parse `git status --porcelain=v2 -z`
---@param stdout string
---@return Gitview.FileEntry[]
function M.parse_v2(stdout)
  if not stdout or stdout == "" then
    return {}
  end

  local parts = vim.split(stdout, "\0", { plain = true })
  local entries = {}
  local i = 1

  while i <= #parts do
    local head = parts[i]
    if head == "" then
      i = i + 1
    elseif head:sub(1, 2) == "? " then
      local path = head:sub(3)
      i = i + 1
      add_entry(entries, {
        id = "wt:" .. path,
        path = path,
        status = "?",
        section = "untracked",
        x = "?",
        y = "?",
        compare = compare_for("untracked", "?", "?"),
      })
    elseif head:sub(1, 2) == "1 " then
      local fields = vim.split(head, " ", { plain = true })
      local xy = fields[2] or "??"
      local x, y = xy:sub(1, 1), xy:sub(2, 2)
      local path
      if #fields >= 9 then
        path = table.concat(fields, " ", 9)
      else
        i = i + 1
        path = parts[i] or ""
      end
      i = i + 1

      if x == "?" and y == "?" then
        add_entry(entries, {
          id = "wt:" .. path,
          path = path,
          status = "?",
          section = "untracked",
          x = x,
          y = y,
          compare = compare_for("untracked", x, y),
        })
      else
        local staged, unstaged = xy_flags(x, y)
        if staged then
          local section = "staged"
          if x == "U" or y == "U" then
            section = "conflicted"
          end
          add_entry(entries, {
            id = "idx:" .. path,
            path = path,
            status = sign_for_xy(x, y),
            section = section,
            x = x,
            y = y,
            compare = compare_for(section, x, y),
          })
        end
        if unstaged then
          local section = "changes"
          if x == "U" or y == "U" then
            section = "conflicted"
          end
          add_entry(entries, {
            id = "wt:" .. path,
            path = path,
            status = sign_for_xy(x, y),
            section = section,
            x = x,
            y = y,
            compare = compare_for("changes", x, y),
          })
        end
      end
    elseif head:sub(1, 2) == "2 " then
      local fields = vim.split(head, " ", { plain = true })
      local xy = fields[2] or "R "
      local x, y = xy:sub(1, 1), xy:sub(2, 2)
      local oldpath, newpath
      if #fields >= 10 then
        oldpath = fields[9]
        newpath = table.concat(fields, " ", 10)
      else
        i = i + 1
        oldpath = parts[i] or ""
        i = i + 1
        newpath = parts[i] or oldpath
      end
      i = i + 1

      local staged, unstaged = xy_flags(x, y)
      local sign = (x == "C" or y == "C") and "C" or "R"

      if staged then
        add_entry(entries, {
          id = "idx:" .. newpath,
          path = newpath,
          path_old = oldpath,
          status = sign,
          section = "staged",
          x = x,
          y = y,
          compare = {
            left = { kind = "HEAD" },
            right = { kind = "WORKTREE" },
          },
        })
      end
      if unstaged then
        add_entry(entries, {
          id = "wt:" .. newpath,
          path = newpath,
          path_old = oldpath,
          status = sign,
          section = "changes",
          x = x,
          y = y,
          compare = {
            left = { kind = "HEAD", path_old = oldpath },
            right = { kind = "WORKTREE" },
          },
        })
      end
    elseif head:sub(1, 2) == "u " then
      local fields = vim.split(head, " ", { plain = true })
      local xy = fields[2] or "UU"
      local x, y = xy:sub(1, 1), xy:sub(2, 2)
      local path
      if #fields >= 11 then
        path = table.concat(fields, " ", 11)
      else
        i = i + 1
        path = parts[i] or ""
      end
      i = i + 1
      add_entry(entries, {
        id = "conf:" .. path,
        path = path,
        status = "U",
        section = "conflicted",
        x = x,
        y = y,
        compare = compare_for("conflicted", x, y),
      })
    else
      i = i + 1
    end
  end

  return entries
end

---@param entries Gitview.FileEntry[]
---@return Gitview.FileEntry[] flat
function M.sort_and_flatten(entries)
  local by_section = { changes = {}, staged = {}, untracked = {}, conflicted = {} }
  for _, e in ipairs(entries) do
    local list = by_section[e.section]
    if list then
      list[#list + 1] = e
    end
  end

  table.sort(by_section.changes, function(a, b)
    return a.path < b.path
  end)
  table.sort(by_section.staged, function(a, b)
    return a.path < b.path
  end)
  table.sort(by_section.untracked, function(a, b)
    return a.path < b.path
  end)
  table.sort(by_section.conflicted, function(a, b)
    return a.path < b.path
  end)

  local flat = {}
  for _, section in ipairs(SECTION_ORDER) do
    for _, e in ipairs(by_section[section]) do
      flat[#flat + 1] = e
    end
  end
  return flat
end

---@param entries Gitview.FileEntry[]
---@param signs table
---@param collapsed table<string, boolean>|nil
---@param use_tree boolean|nil
---@return string[] lines
---@return table line_to_entry table<number, Gitview.FileEntry>
---@return table line_to_folder table<number, string>
function M.render_lines(entries, signs, collapsed, use_tree)
  collapsed = collapsed or {}
  local tree = use_tree ~= false and require("gitview.tree")

  local by_section = { changes = {}, staged = {}, untracked = {}, conflicted = {} }
  for _, e in ipairs(entries) do
    by_section[e.section][#by_section[e.section] + 1] = e
  end

  local lines = {}
  local line_to_entry = {}
  local line_to_folder = {}
  local section_titles = {
    changes = "Changes",
    staged = "Staged",
    untracked = "Untracked",
    conflicted = "Conflicted",
  }

  local function sign_char(e)
    local s = signs[e.status:lower()] or e.status
    if #s > 1 then
      return e.status
    end
    return s
  end

  local has_any = false
  for _, section in ipairs(SECTION_ORDER) do
    local list = by_section[section]
    if #list > 0 then
      has_any = true
      lines[#lines + 1] = section_titles[section]
      if tree and require("gitview.config").get().layout.tree then
        local section_lines, sec_entries, sec_folders = tree.render_section(section, list, collapsed, signs)
        for i, l in ipairs(section_lines) do
          lines[#lines + 1] = l
          if sec_entries[i] then
            line_to_entry[#lines] = sec_entries[i]
          end
          if sec_folders[i] then
            line_to_folder[#lines] = sec_folders[i]
          end
        end
      else
        for _, e in ipairs(list) do
          lines[#lines + 1] = string.format("  %s  %s", sign_char(e), e.path)
          line_to_entry[#lines] = e
        end
      end
      lines[#lines + 1] = ""
    end
  end

  if not has_any then
    lines[#lines + 1] = "No changes"
  end

  return lines, line_to_entry, line_to_folder
end

return M
