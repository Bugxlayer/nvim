local M = {}

function M.check()
  vim.health.start("gitview")

  if vim.fn.has("nvim-0.10") ~= 1 then
    vim.health.error("Neovim 0.10+ required")
  else
    vim.health.ok("Neovim version OK")
  end

  local cfg = require("gitview.config").get()
  if vim.fn.executable(cfg.git.cmd) ~= 1 then
    vim.health.error("Git executable not found: " .. cfg.git.cmd)
    return
  end
  vim.health.ok("Git executable: " .. cfg.git.cmd)

  local ver = vim.fn.system({ cfg.git.cmd, "--version" }):gsub("\n", "")
  vim.health.info(ver)

  local repo = require("gitview.git").find_root(vim.loop.cwd())
  if repo then
    vim.health.ok("Inside repository: " .. repo.root)
  else
    vim.health.warn("Not inside a git repository (cwd)")
  end
end

return M
