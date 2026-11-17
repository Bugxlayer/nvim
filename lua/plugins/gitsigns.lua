return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      { "<A-j>", mode = "n", desc = "Git: next hunk (this file)" },
      { "<A-k>", mode = "n", desc = "Git: previous hunk (this file)" },
      { "<A-S-j>", mode = "n", desc = "Git: next hunk (all changed files)" },
      { "<A-S-k>", mode = "n", desc = "Git: previous hunk (all changed files)" },
      { "<leader>gJ", mode = "n", desc = "Git: next hunk (all changed files)" },
      { "<leader>gK", mode = "n", desc = "Git: previous hunk (all changed files)" },
      { "<leader>gb", mode = "n", desc = "Toggle git inline blame (gitsigns)" },
      { "<leader>gh", mode = "n", desc = "Git: preview hunk inline (gitsigns)" },
      { "<leader>gH", mode = "n", desc = "Git: preview hunk popup (gitsigns)" },
    },
    opts = {
      signcolumn = true,
      numhl = true,
      linehl = false,
      signs = {
        add = { text = "+" },
        change = { text = "▎" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "~" },
        untracked = { text = "▎" },
      },
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)

      local gs = require("gitsigns")

      local function nav_hunk_file(direction)
        if vim.wo.diff then
          vim.cmd.normal({ direction == "next" and "]c" or "[c", bang = true })
        else
          gs.nav_hunk(direction)
        end
      end

      -- lnext/lprev only step within the current buffer; use an explicit index instead.
      local repo_hunks = { items = nil, index = 0 }

      local function clear_repo_hunks()
        repo_hunks.items = nil
        repo_hunks.index = 0
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "GitSignsUpdate",
        callback = clear_repo_hunks,
      })
      vim.api.nvim_create_autocmd({ "BufWritePost", "ShellCmdPost" }, {
        callback = clear_repo_hunks,
      })

      local function repo_item_path(item)
        if item.filename and item.filename ~= "" then
          return vim.fn.fnamemodify(item.filename, ":p")
        end
        if item.bufnr and item.bufnr > 0 and vim.api.nvim_buf_is_valid(item.bufnr) then
          local name = vim.api.nvim_buf_get_name(item.bufnr)
          if name ~= "" then
            return vim.fn.fnamemodify(name, ":p")
          end
        end
        return ""
      end

      local function repo_index_at_cursor(items)
        local cur_path = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":p")
        local cur_lnum = vim.fn.line(".")
        local index = 0
        for i, item in ipairs(items) do
          local path = repo_item_path(item)
          if path == "" then
            goto continue
          end
          if path < cur_path or (path == cur_path and item.lnum <= cur_lnum) then
            index = i
          else
            break
          end
          ::continue::
        end
        return index
      end

      local function repo_jump_to(item, index, total)
        local path = repo_item_path(item)
        if path == "" then
          return
        end
        if vim.fn.fnamemodify(vim.fn.expand("%:p"), ":p") ~= path then
          vim.cmd("keepjumps edit " .. vim.fn.fnameescape(path))
        end
        vim.fn.cursor(item.lnum, 1)
        vim.cmd("normal! zz")
        vim.api.nvim_echo({ { ("Hunk %d of %d"):format(index, total), "None" } }, false, {})
      end

      local function nav_hunk_repo(direction)
        local function step()
          local items = repo_hunks.items
          if not items or #items == 0 then
            vim.notify("No hunks in repo", vim.log.levels.WARN)
            return
          end

          if repo_hunks.index < 1 or repo_hunks.index > #items then
            repo_hunks.index = repo_index_at_cursor(items)
          end

          if direction == "next" then
            repo_hunks.index = repo_hunks.index + 1
            if repo_hunks.index > #items then
              repo_hunks.index = 1
            end
          else
            if repo_hunks.index == 0 then
              repo_hunks.index = #items
            else
              repo_hunks.index = repo_hunks.index - 1
              if repo_hunks.index < 1 then
                repo_hunks.index = #items
              end
            end
          end

          repo_jump_to(items[repo_hunks.index], repo_hunks.index, #items)
        end

        if repo_hunks.items and #repo_hunks.items > 0 then
          step()
          return
        end

        gs.setqflist("all", { use_location_list = true, nr = 0, open = false }, function(err)
          if err then
            vim.notify("Git hunks: " .. tostring(err), vim.log.levels.ERROR)
            return
          end

          repo_hunks.items = vim.fn.getloclist(0, { items = 0 }).items or {}
          if #repo_hunks.items == 0 then
            vim.notify("No hunks in repo", vim.log.levels.WARN)
            return
          end

          repo_hunks.index = repo_index_at_cursor(repo_hunks.items)
          step()
        end)
      end

      vim.keymap.set("n", "<A-j>", function()
        nav_hunk_file("next")
      end, { desc = "Git: next hunk (this file)" })
      vim.keymap.set("n", "<A-k>", function()
        nav_hunk_file("prev")
      end, { desc = "Git: previous hunk (this file)" })
      vim.keymap.set("n", "<A-S-j>", function()
        nav_hunk_repo("next")
      end, { desc = "Git: next hunk (all changed files)" })
      vim.keymap.set("n", "<A-S-k>", function()
        nav_hunk_repo("prev")
      end, { desc = "Git: previous hunk (all changed files)" })
      vim.keymap.set("n", "<leader>gJ", function()
        nav_hunk_repo("next")
      end, { desc = "Git: next hunk (all changed files)" })
      vim.keymap.set("n", "<leader>gK", function()
        nav_hunk_repo("prev")
      end, { desc = "Git: previous hunk (all changed files)" })

      vim.keymap.set("n", "<leader>gb", function()
        gs.toggle_current_line_blame()
      end, { desc = "Toggle git inline blame (gitsigns)" })
      vim.keymap.set("n", "<leader>gh", function()
        gs.preview_hunk_inline()
      end, { desc = "Git: preview hunk inline (gitsigns)" })
      vim.keymap.set("n", "<leader>gH", function()
        gs.preview_hunk()
      end, { desc = "Git: preview hunk popup (gitsigns)" })

      local green = "#56d364"
      local blue = "#61afef"
      local red = "#f7768e"

      local function gs_sign_and_nr(base, fg)
        vim.api.nvim_set_hl(0, base, { fg = fg })
        vim.api.nvim_set_hl(0, base .. "Nr", { fg = fg })
      end

      gs_sign_and_nr("GitSignsAdd", green)
      gs_sign_and_nr("GitSignsUntracked", green)
      gs_sign_and_nr("GitSignsChange", blue)
      gs_sign_and_nr("GitSignsChangedelete", blue)
      gs_sign_and_nr("GitSignsDelete", red)
      gs_sign_and_nr("GitSignsTopdelete", red)
      vim.api.nvim_set_hl(0, "GitSignsDeleteVirtLn", { fg = red })
    end,
  },
}
