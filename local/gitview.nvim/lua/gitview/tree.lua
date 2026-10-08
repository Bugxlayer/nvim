local config = require("gitview.config")

local M = {}

---@class Gitview.TreeNode
---@field name string
---@field children table<string, Gitview.TreeNode>
---@field files Gitview.FileEntry[]

local function new_node(name)
  return { name = name, children = {}, files = {} }
end

---@param entries Gitview.FileEntry[]
---@return Gitview.TreeNode
function M.build(entries)
  local root = new_node("")
  for _, entry in ipairs(entries) do
    local parts = vim.split(entry.path, "/", { plain = true })
    local basename = table.remove(parts) or entry.path
    local node = root
    local prefix = {}
    for _, part in ipairs(parts) do
      prefix[#prefix + 1] = part
      if not node.children[part] then
        node.children[part] = new_node(part)
        node.children[part].dir_path = table.concat(prefix, "/")
      end
      node = node.children[part]
    end
    entry._basename = basename
    node.files[#node.files + 1] = entry
  end
  return root
end

local function sorted_keys(t)
  local keys = {}
  for k in pairs(t) do
    keys[#keys + 1] = k
  end
  table.sort(keys)
  return keys
end

local function sort_files(files)
  table.sort(files, function(a, b)
    return (a._basename or a.path) < (b._basename or b.path)
  end)
end

---@param section string
---@param dir_path string
---@return string
function M.collapse_key(section, dir_path)
  return section .. "\31" .. dir_path
end

---@param node Gitview.TreeNode
---@param depth integer
---@param section string
---@param collapsed table<string, boolean>
---@param signs table
---@param lines string[]
---@param line_to_entry table<number, Gitview.FileEntry>
---@param line_to_folder table<number, string>
local function render_node(node, depth, section, collapsed, signs, lines, line_to_entry, line_to_folder)
  local step = config.get().layout.tree_indent or 1
  local indent = string.rep(" ", depth * step)

  local function sign_char(e)
    local s = signs[e.status:lower()] or e.status
    if #s > 1 then
      return e.status
    end
    return s
  end

  for _, name in ipairs(sorted_keys(node.children)) do
    local child = node.children[name]
    local dir_path = child.dir_path or name
    local key = M.collapse_key(section, dir_path)
    local is_collapsed = collapsed[key]
    local icon = is_collapsed and "▸" or "▾"
    lines[#lines + 1] = string.format("%s%s %s", indent, icon, name)
    line_to_folder[#lines] = key

    if not is_collapsed then
      render_node(child, depth + 1, section, collapsed, signs, lines, line_to_entry, line_to_folder)
    end
  end

  sort_files(node.files)
  for _, e in ipairs(node.files) do
    local name = e._basename or vim.fn.fnamemodify(e.path, ":t")
    lines[#lines + 1] = string.format("%s%s %s", indent, sign_char(e), name)
    line_to_entry[#lines] = e
  end
end

---@param section string
---@param entries Gitview.FileEntry[]
---@param collapsed table<string, boolean>
---@param signs table
---@return string[] lines
---@return table<number, Gitview.FileEntry> line_to_entry
---@return table<number, string> line_to_folder
function M.render_section(section, entries, collapsed, signs)
  local lines = {}
  local line_to_entry = {}
  local line_to_folder = {}
  if #entries == 0 then
    return lines, line_to_entry, line_to_folder
  end
  local root = M.build(entries)
  render_node(root, 0, section, collapsed, signs, lines, line_to_entry, line_to_folder)
  return lines, line_to_entry, line_to_folder
end

return M
