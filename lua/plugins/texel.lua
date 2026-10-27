-- TEMPORARY: local checkout of texel.nvim for testing.
-- To remove: delete this file and drop `enabled = false` in pdfview.lua.
return {
	dir = "~/dev/texel.nvim",
	name = "texel.nvim",
	lazy = false,
	config = function()
		require("texel").setup({
			keymaps = "default",
			scroll = {
				-- Animate the mouse wheel and <C-d>/<C-u>/<C-f>/<C-b> in documents
				-- too, not only jumps (J/K, gp, links: scroll.mode).
				smooth = { mouse = true, keys = true },
			},
		})
	end,
}
