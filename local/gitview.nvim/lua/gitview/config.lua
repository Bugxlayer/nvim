local M = {}

local defaults = {
  git = {
    cmd = "git",
  },
  layout = {
    columns = { 20, 40, 40 },
    open_in = "current", -- "current" | "tab"
    tree = true,
    tree_indent = 1, -- spaces per directory depth in file tree
    diff_filler = false, -- false = no filler rows (empty gaps); linematch stays on
  },
  signs = {
    added = "A",
    modified = "M",
    deleted = "D",
    renamed = "R",
    copied = "C",
    untracked = "?",
    unmerged = "U",
  },
  keymaps = {
    file = {
      close = "q",
      close_alt = "<Esc>",
      refresh = "r",
      stage = "s",
      unstage = "u",
      stage_all = "S",
      unstage_all = "U",
      next_file = "]f",
      prev_file = "[f",
      first_file = "gg",
      last_file = "G",
      compare_cycle = "o",
      commit = "c",
      push = "P",
      pull = "p",
      open_file = "gf",
      filter = "/",
    },
    diff = {
      close = "q",
      close_alt = "<Esc>",
      next_hunk = "]c",
      prev_hunk = "[c",
      stage_hunk = "hs",
      unstage_hunk = "hu",
      reset_hunk = "hr",
    },
  },
  compare = {
    -- Diff panes default to last commit (HEAD) vs working tree (current file on disk).
    default = { left = "HEAD", right = "WORKTREE" },
    allow_cycle = true, -- `o` in file pane: HEAD/WT, HEAD/INDEX, INDEX/WT
  },
  highlights = {
    -- Diff colors apply to the **Current** (right) pane only; Last commit (middle) stays plain.
    diff = {
      -- add = { bg = "#1a3d2a", fg = "#7cfc9a" },
      -- change = { bg = "#3d3618", fg = "#f9e64f" },
      -- delete = { bg = "#3d1a1a", fg = "#ff6b6b" },
    },
  },
  auto_refresh = false,
  single_instance = true,
  untracked_files = "all", -- "all" | "normal"
  max_file_size = 1024 * 1024, -- 1 MiB; skip diff above this
  integrations = {
    telescope = true,
    lualine = true,
  },
}

local function deep_extend(b, a)
  for k, v in pairs(a) do
    if type(v) == "table" and type(b[k]) == "table" then
      deep_extend(b[k], v)
    else
      b[k] = v
    end
  end
  return b
end

function M.setup(user_opts)
  M.options = vim.deepcopy(defaults)
  if user_opts then
    deep_extend(M.options, user_opts)
  end

  local cols = M.options.layout.columns
  local sum = cols[1] + cols[2] + cols[3]
  if sum ~= 100 then
    vim.notify(
      string.format("gitview: layout.columns must sum to 100 (got %d); using 20/40/40", sum),
      vim.log.levels.WARN
    )
    M.options.layout.columns = { 20, 40, 40 }
  end

  return M.options
end

function M.get()
  if not M.options then
    M.setup({})
  end
  return M.options
end

return M
