local ok, telescope = pcall(require, "telescope")
if not ok then
  return
end

local gitview = require("gitview")

telescope.register_extension({
  exports = {
    gitview = function()
      gitview.open()
    end,
  },
})
