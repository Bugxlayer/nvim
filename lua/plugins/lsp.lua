return {
    "neovim/nvim-lspconfig",

    config = function()
        local python_env = require("python_env")

        local pyright_root_markers = {
            ".git",
            "pyproject.toml",
            "setup.py",
            "setup.cfg",
            "requirements.txt",
        }

        vim.lsp.config("pyright", {
            root_markers = pyright_root_markers,
            -- Neovim 0.12+ async root_dir: must call on_dir(), not return a path.
            root_dir = function(bufnr, on_dir)
                local fname = vim.api.nvim_buf_get_name(bufnr)
                if fname == "" then
                    return
                end
                local root = vim.fs.root(fname, pyright_root_markers)
                if root then
                    on_dir(root)
                end
            end,
            settings = {
                python = {
                    analysis = {
                        typeCheckingMode = "off",
                        autoSearchPaths = true,
                        useLibraryCodeForTypes = true,
                        diagnosticMode = "workspace",
                    },
                },
            },
            before_init = function(params, config)
                local root = params.rootUri and vim.uri_to_fname(params.rootUri) or nil
                local venv = root and python_env.venv_for_root(root) or python_env.get_venv()
                if not venv then
                    return
                end
                config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
                    python = {
                        venvPath = vim.fs.dirname(venv),
                        venv = vim.fn.fnamemodify(venv, ":t"),
                    },
                })
            end,
        })

        vim.lsp.enable("pyright")
    end,
}
