if vim.g.loaded_gitview then
  return
end
vim.g.loaded_gitview = true

vim.api.nvim_create_user_command("GitView", function(opts)
  require("gitview").open({ path = opts.args ~= "" and opts.args or nil })
end, { nargs = "?", desc = "Open gitview 3-pane Git UI" })

vim.api.nvim_create_user_command("GitViewClose", function()
  require("gitview").close()
end, { desc = "Close gitview" })

vim.api.nvim_create_user_command("GitViewToggle", function()
  require("gitview").toggle()
end, { desc = "Toggle gitview" })
