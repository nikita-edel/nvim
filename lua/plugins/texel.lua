-- TEMPORARY: local checkout of texel.nvim for testing.
-- To remove: delete this file and drop `enabled = false` in pdfview.lua.
return {
	dir = "~/dev/texel.nvim",
	name = "texel.nvim",
	lazy = false,
	config = function()
		require("texel").setup({ keymaps = "default" })
	end,
}
