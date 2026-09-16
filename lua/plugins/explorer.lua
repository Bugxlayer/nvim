return {
  -- LazyVim v8 defaults to the Snacks tree explorer; use built-in netrw instead.
  { import = "lazyvim.plugins.extras.editor.snacks_explorer", enabled = false },
  { import = "lazyvim.plugins.extras.editor.neo-tree", enabled = false },

  {
    "folke/snacks.nvim",
    opts = {
      explorer = {
        enabled = false,
        replace_netrw = false,
      },
    },
  },
}
