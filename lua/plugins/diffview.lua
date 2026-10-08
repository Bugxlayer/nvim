return {
  {
    "sindrets/diffview.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },

    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
    },

    keys = {
      {
        "<leader>gs",
        "<cmd>DiffviewOpen<cr>",
        desc = "Git stage/review (files + diff)",
      },
      {
        "<leader>gt",
        "<cmd>DiffviewToggleFiles<cr>",
        desc = "Toggle changed-files panel",
      },
      {
        "<leader>gq",
        "<cmd>DiffviewClose<cr>",
        desc = "Close diff view",
      },
      {
        "<leader>gf",
        "<cmd>DiffviewFocusFiles<cr>",
        desc = "Focus changed-files panel",
      },
    },

    opts = {
      watch_index = true,

      view = {
        -- Diffview naming: "horizontal" = side-by-side (A | B), not top/bottom.
        default = {
          layout = "diff2_horizontal",
        },
        file_history = {
          layout = "diff2_horizontal",
        },
        merge_tool = {
          layout = "diff3_horizontal",
        },
      },

      file_panel = {
        listing_style = "tree",
        win_config = {
          type = "split",
          position = "left",
          width = 40,
        },
      },
    },

    config = function(_, opts)
      local actions = require("diffview.actions")

      local function resize_file_panel(delta)
        return function()
          local view = require("diffview.lib").get_current_view()
          if not view or not view.panel:is_open() then
            return
          end

          local winid = view.panel.winid
          local width = vim.api.nvim_win_get_width(winid)
          vim.api.nvim_win_set_width(winid, math.max(24, math.min(100, width + delta)))
        end
      end

      local panel_maps = {
        { "n", "<leader>gt", actions.toggle_files, { desc = "Toggle changed-files panel" } },
        { "n", "<leader>b", actions.toggle_files, { desc = "Toggle changed-files panel" } },
        { "n", "<C-Left>", resize_file_panel(-4), { desc = "Narrow changed-files panel" } },
        { "n", "<C-Right>", resize_file_panel(4), { desc = "Widen changed-files panel" } },
      }

      opts.keymaps = vim.tbl_deep_extend("force", opts.keymaps or {}, {
        view = panel_maps,
        file_panel = panel_maps,
        diff2 = {
          { "n", "<leader>gt", actions.toggle_files, { desc = "Toggle changed-files panel" } },
          { "n", "<C-Left>", resize_file_panel(-4), { desc = "Narrow changed-files panel" } },
          { "n", "<C-Right>", resize_file_panel(4), { desc = "Widen changed-files panel" } },
        },
      })

      require("diffview").setup(opts)
    end,
  },
}
