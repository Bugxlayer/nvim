return {
	"ryansaxe/buffergolf.nvim",
	dependencies = { "nvim-mini/mini.diff" },
	config = function()
		require("buffergolf").setup()
	end,
}
