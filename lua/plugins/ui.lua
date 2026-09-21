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

-- Grow/shrink the terminal window. Floats are sized through snacks options
-- (a height <= 1 is a fraction of the editor), splits through :resize.
local function term_resize(delta)
  ---@param self snacks.terminal
  return function(self)
    if self:is_floating() then
      local height = self.opts.height or 0.9
      if height > 0 and height <= 1 then
        self.opts.height = math.min(0.95, math.max(0.15, height + delta * 0.05))
      else
        self.opts.height = math.max(3, height + delta * 2)
      end
      self:update()
    else
      vim.cmd(("resize %+d"):format(delta * 2))
    end
  end
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

  -- No key hint popup after <leader> / <C-w>
  { "folke/which-key.nvim", enabled = false },

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
    opts = function(_, opts)
      opts.cmdline = vim.tbl_deep_extend("force", opts.cmdline or {}, {
        view = "cmdline", -- classic bar at the bottom (not floating popup)
      })

      -- No popup for LazyVim's own warnings; still listed in `:Noice`
      opts.routes = opts.routes or {}
      table.insert(opts.routes, {
        filter = {
          event = "notify",
          cond = function(message)
            return type(message.opts) == "table" and message.opts.title == "LazyVim"
          end,
        },
        opts = { skip = true },
      })
      return opts
    end,
  },

  {
    "folke/snacks.nvim",
    keys = {
      { "<leader><space>", false },
    },
    opts = function(_, opts)
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
      local compact = { width = 0.58, height = 0.62, min_width = 64 }
      return vim.tbl_deep_extend("force", opts or {}, {
        picker = {
          sources = picker_sources,
          -- Snacks picker (LazyVim default; telescope-like layout)
          layout = {
            preset = function()
              return vim.o.columns >= 110 and "telescope" or "vertical"
            end,
          },
          layouts = {
            default = { layout = compact },
            telescope = { layout = compact },
            vertical = { layout = { width = 0.48, height = 0.58, min_width = 64, min_height = 22 } },
            dropdown = { layout = { width = 0.42, height = 0.55, min_width = 64 } },
          },
        },
        terminal = {
          win = {
            keys = {
              resize_up = {
                "<C-Up>",
                term_resize(1),
                desc = "Increase Terminal Height",
                mode = { "n", "t" },
              },
              resize_down = {
                "<C-Down>",
                term_resize(-1),
                desc = "Decrease Terminal Height",
                mode = { "n", "t" },
              },
            },
          },
        },
      })
    end,
  },
}
