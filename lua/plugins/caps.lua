return {
	"nikita-edel/capsdetect.nvim",
	config = function()
		require("capsdetect").setup({
			indicator = {
				highlight = {
					fg = "#ff0000",
				},
			},
		})
	end,
}
