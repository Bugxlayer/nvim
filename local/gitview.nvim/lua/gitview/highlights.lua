local config = require("gitview.config")

local M = {}

local DIFF_GROUPS = {
  "DiffAdd",
  "DiffChange",
  "DiffDelete",
  "DiffText",
  "DiffLineAdd",
  "DiffLineChange",
  "DiffLineDelete",
}

function M.setup()
  local hl = vim.api.nvim_create_augroup("GitViewHighlights", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = hl,
    callback = function()
      M.apply()
      M.refresh_diff_wins()
    end,
  })
  M.apply()
end

function M.apply()
  vim.api.nvim_set_hl(0, "GitViewSection", { link = "Title", default = true })
  vim.api.nvim_set_hl(0, "GitViewFolder", { link = "Directory", default = true })
  vim.api.nvim_set_hl(0, "GitViewFile", { link = "Normal", default = true })
  vim.api.nvim_set_hl(0, "GitViewSelected", { link = "CursorLine", default = true })
  vim.api.nvim_set_hl(0, "GitViewMessage", { link = "Comment", default = true })

  vim.api.nvim_set_hl(0, "GitViewSignAdd", { link = "GitViewDiffAdd", default = true })
  vim.api.nvim_set_hl(0, "GitViewSignChange", { link = "GitViewDiffChange", default = true })
  vim.api.nvim_set_hl(0, "GitViewSignDelete", { link = "GitViewDiffDelete", default = true })

  M.apply_diff()
end

--- Colors only on the **current** (right) diff pane: green add, red delete, yellow change.
function M.apply_diff()
  local user = config.get().highlights or {}
  local overrides = user.diff or {}

  vim.api.nvim_set_hl(
    0,
    "GitViewDiffAdd",
    vim.tbl_extend("force", {
      bg = "#1a3d2a",
      fg = "#7cfc9a",
      default = true,
    }, overrides.add or {})
  )

  vim.api.nvim_set_hl(
    0,
    "GitViewDiffDelete",
    vim.tbl_extend("force", {
      bg = "#3d1a1a",
      fg = "#ff6b6b",
      default = true,
    }, overrides.delete or {})
  )

  vim.api.nvim_set_hl(
    0,
    "GitViewDiffChange",
    vim.tbl_extend("force", {
      bg = "#3d3618",
      fg = "#f9e64f",
      default = true,
    }, overrides.change or {})
  )

  vim.api.nvim_set_hl(0, "GitViewDiffText", { link = "GitViewDiffChange", default = true })
  vim.api.nvim_set_hl(0, "GitViewDiffLineAdd", { link = "GitViewDiffAdd", default = true })
  vim.api.nvim_set_hl(0, "GitViewDiffLineChange", { link = "GitViewDiffChange", default = true })
  vim.api.nvim_set_hl(0, "GitViewDiffLineDelete", { link = "GitViewDiffDelete", default = true })
end

local function winhighlight_plain()
  local parts = {}
  for _, name in ipairs(DIFF_GROUPS) do
    parts[#parts + 1] = name .. ":Normal"
  end
  return table.concat(parts, ",")
end

local function winhighlight_current()
  return table.concat({
    "DiffAdd:GitViewDiffAdd",
    "DiffChange:GitViewDiffChange",
    "DiffDelete:GitViewDiffDelete",
    "DiffText:GitViewDiffText",
    "DiffLineAdd:GitViewDiffLineAdd",
    "DiffLineChange:GitViewDiffLineChange",
    "DiffLineDelete:GitViewDiffLineDelete",
  }, ",")
end

---@param winid integer
---@param side "old"|"new"
function M.apply_diff_winhighlight(winid, side)
  if not winid or not vim.api.nvim_win_is_valid(winid) then
    return
  end
  local wh = side == "old" and winhighlight_plain() or winhighlight_current()
  vim.api.nvim_set_option_value("winhighlight", wh, { win = winid })
end

function M.refresh_diff_wins()
  local st = require("gitview.state").get()
  if not st or st.closed then
    return
  end
  M.apply_diff_winhighlight(st.win_old, "old")
  M.apply_diff_winhighlight(st.win_new, "new")
end

return M
