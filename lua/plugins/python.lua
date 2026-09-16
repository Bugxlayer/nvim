local function local_venv_python(root)
  if not root or root == "" then
    return nil
  end
  root = vim.fs.normalize(root)
  local candidates = vim.fn.has("win32") == 1
      and {
        root .. "/.venv/Scripts/python.exe",
        root .. "/venv/Scripts/python.exe",
      }
    or {
      root .. "/.venv/bin/python",
      root .. "/venv/bin/python",
    }
  for _, python in ipairs(candidates) do
    if vim.fn.filereadable(python) == 1 then
      return python
    end
  end
  return nil
end

---@type table<string, boolean>
local auto_tried_roots = {}

return {
  {
    "neovim/nvim-lspconfig",
    ---@param opts PluginLspOpts
    opts = function(_, opts)
      for _, name in ipairs({ "ruff", "ruff_lsp" }) do
        opts.servers[name] = vim.tbl_deep_extend("force", opts.servers[name] or {}, { enabled = false })
      end
      opts.servers.pyright = vim.tbl_deep_extend("force", opts.servers.pyright or {}, {
        enabled = true,
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "off",
              diagnosticMode = "openFilesOnly",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
            },
          },
        },
      })
    end,
  },

  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "pyright",
        "debugpy",
      },
    },
  },

  {
    "linux-cultist/venv-selector.nvim",
    opts = {
      options = {
        notify_user_on_venv_activation = false,
        cached_venv_automatic_activation = true,
        enable_cached_venvs = true,
      },
    },
    config = function(_, opts)
      require("venv-selector").setup(opts)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("lazyvim_auto_venv", { clear = true }),
        pattern = "python",
        callback = function(args)
          -- Run after venv-selector's cached restore (~1s)
          vim.defer_fn(function()
            local bufnr = args.buf
            if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= "python" then
              return
            end
            if vim.b[bufnr].venv_selector_disabled then
              return
            end
            if require("venv-selector.uv2").is_uv_buffer(bufnr) then
              return
            end

            local path_mod = require("venv-selector.path")
            if path_mod.current_python_path and path_mod.current_python_path ~= "" then
              return
            end

            local root = require("venv-selector.project_root").key_for_buf(bufnr) or LazyVim.root()
            if not root or auto_tried_roots[root] then
              return
            end
            auto_tried_roots[root] = true

            local python = local_venv_python(root)
            if python then
              require("venv-selector").activate_from_path(python, "venv")
            end
          end, 1100)
        end,
      })
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.sections.lualine_x = opts.sections.lualine_x or {}
      table.insert(opts.sections.lualine_x, 1, {
        function()
          local ok, mod = pcall(require, "venv-selector.statusline.lualine")
          if not ok then
            return ""
          end
          return mod.render()
        end,
        cond = function()
          return vim.bo.filetype == "python"
        end,
      })
    end,
  },
}
