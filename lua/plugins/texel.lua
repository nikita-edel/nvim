local dir = vim.fn.expand("~/dev/texel.nvim")

return {
	cond = vim.fn.isdirectory(dir) == 1,
	dir = dir,
	name = "texel.nvim",
	lazy = false,
	config = function()
		require("texel").setup({
			keymaps = "default",
			-- gs goes between the source and the text view only; the full
			-- render is still :Texel full (or :Texel split full).
			markdown = { modes = { "text" } },
			scroll = {
				-- Animate the mouse wheel and <C-d>/<C-u>/<C-f>/<C-b> in documents
				smooth = { mouse = true, keys = true },
			},
		})
	end,
}
