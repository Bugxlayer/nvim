-- Status line only (does not change lunaperche in the editor)
local lualine_lunaperche = {
  normal = {
    a = { fg = "#e8e8e8", bg = "#303030", gui = "bold" },
    b = { fg = "#e0e0e0", bg = "#262626" },
    c = { fg = "#d4d4d4", bg = "#1a1a1a" },
  },
  insert = {
    a = { fg = "#1a1a1a", bg = "#87afaf", gui = "bold" },
    b = { fg = "#e0e0e0", bg = "#262626" },
    c = { fg = "#d4d4d4", bg = "#1a1a1a" },
  },
  visual = {
    a = { fg = "#1a1a1a", bg = "#afaf87", gui = "bold" },
    b = { fg = "#e0e0e0", bg = "#262626" },
    c = { fg = "#d4d4d4", bg = "#1a1a1a" },
  },
  replace = {
    a = { fg = "#1a1a1a", bg = "#af5f5f", gui = "bold" },
    b = { fg = "#e0e0e0", bg = "#262626" },
    c = { fg = "#d4d4d4", bg = "#1a1a1a" },
  },
  command = {
    a = { fg = "#1a1a1a", bg = "#5f875f", gui = "bold" },
    b = { fg = "#e0e0e0", bg = "#262626" },
    c = { fg = "#d4d4d4", bg = "#1a1a1a" },
  },
  terminal = {
    a = { fg = "#e8e8e8", bg = "#303030", gui = "bold" },
    b = { fg = "#e0e0e0", bg = "#262626" },
    c = { fg = "#d4d4d4", bg = "#1a1a1a" },
  },
  inactive = {
    a = { fg = "#888888", bg = "#1a1a1a", gui = "bold" },
    b = { fg = "#888888", bg = "#1a1a1a" },
    c = { fg = "#888888", bg = "#1a1a1a" },
  },
}

local function current_file_path()
  local path = vim.fn.expand("%:p")
  if path == "" then
    return ""
  end
  return vim.fn.fnamemodify(path, ":~:.")
end

local function copy_current_file_path()
  local path = vim.fn.expand("%:p")
  if path == "" then
    return
  end
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path, vim.log.levels.INFO, { title = "File path" })
end

local lualine_full_path = {
  current_file_path,
  on_click = function(_, btn)
    if btn == "l" then
      copy_current_file_path()
    end
  end,
}

return {
  -- No buffer tabs at the top (use <S-h>/<S-l> or [b / ]b to switch buffers)
  { "akinsho/bufferline.nvim", enabled = false },

  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.theme = lualine_lunaperche
      opts.sections = opts.sections or {}
      opts.sections.lualine_z = {}

      -- Replace truncated pretty_path with full path (click to copy)
      for i, comp in ipairs(opts.sections.lualine_c or {}) do
        if type(comp) == "table" and type(comp[1]) == "function" and comp.cond == nil and not comp.icon_only then
          opts.sections.lualine_c[i] = lualine_full_path
          break
        end
      end
    end,
  },

  {
    "folke/noice.nvim",
    opts = {
      cmdline = {
        view = "cmdline", -- classic bar at the bottom (not floating popup)
      },
    },
  },

  {
    "folke/snacks.nvim",
    keys = {
      { "<leader><space>", false },
    },
    opts = function()
      local no_preview = { layout = { preview = false } }
      local picker_sources = {}
      for _, name in ipairs({
        "files",
        "grep", -- find text + live grep
        "grep_buffers",
        "grep_word",
        "recent", -- recent / oldfiles
        "buffers",
        "git_files",
        "git_grep",
      }) do
        picker_sources[name] = no_preview
      end
      return {
        picker = {
          sources = picker_sources,
        },
      }
    end,
  },
}
