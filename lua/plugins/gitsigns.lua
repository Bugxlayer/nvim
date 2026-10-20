return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signcolumn = true,
      numhl = true,
      linehl = true,
      signs = {
        add = { text = "+" },
        change = { text = "▎" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "~" },
        untracked = { text = "▎" },
      },
      on_attach = function(bufnr)
        local gs = require("gitsigns")

        local function map(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
        end

        local function nav(direction, nav_opts)
          if vim.wo.diff then
            vim.cmd.normal({ direction == "next" and "]c" or "[c", bang = true })
          else
            gs.nav_hunk(direction, nav_opts)
          end
        end

        map("]c", function()
          nav("next")
        end, "Git: next hunk (this file)")
        map("[c", function()
          nav("prev")
        end, "Git: previous hunk (this file)")
      end,
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)

      local gs = require("gitsigns")

      local function nav_project(direction)
        gs.setqflist("all", { use_location_list = true, nr = 0, open = false })
        local cmd = direction == "next" and "lnext" or "lprev"
        local ok = pcall(vim.cmd, "keepjumps " .. cmd)
        if not ok then
          vim.notify("No more hunks in repo", vim.log.levels.WARN)
        end
      end

      vim.keymap.set("n", "]C", function()
        nav_project("next")
      end, { desc = "Git: next hunk (all changed files)" })
      vim.keymap.set("n", "[C", function()
        nav_project("prev")
      end, { desc = "Git: previous hunk (all changed files)" })

      vim.keymap.set("n", "<leader>gb", function()
        gs.toggle_current_line_blame()
      end, { desc = "Toggle git inline blame (gitsigns)" })

      local green = "#7fd99a"
      local green_bg = "#1a2e22"

      local function gs_add(name, spec)
        vim.api.nvim_set_hl(0, name, spec)
      end

      gs_add("GitSignsAdd", { fg = green })
      gs_add("GitSignsAddNr", { fg = green })
      gs_add("GitSignsAddLn", { bg = green_bg })
      gs_add("GitSignsAddLnInline", { bg = green_bg })

      gs_add("GitSignsUntracked", { fg = green })
      gs_add("GitSignsUntrackedNr", { fg = green })
      gs_add("GitSignsUntrackedLn", { bg = green_bg })
    end,
  },
}
