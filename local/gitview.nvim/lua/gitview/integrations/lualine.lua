local M = {}

local open = false

vim.api.nvim_create_autocmd("User", {
  pattern = "GitViewOpen",
  callback = function()
    open = true
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "GitViewClose",
  callback = function()
    open = false
  end,
})

function M.component()
  if open then
    return "%#DiffAdd# GitView"
  end
  return ""
end

return M
