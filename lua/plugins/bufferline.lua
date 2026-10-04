return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = "nvim-tree/nvim-web-devicons",
	config = function()
		require("bufferline").setup({
			options = {
				mode = "buffers",
				separator_style = "thin",
			},
		})
		vim.keymap.set("n", "H", "<cmd>BufferLineCyclePrev<cr>")
		vim.keymap.set("n", "L", "<cmd>BufferLineCycleNext<cr>")
	end,
}
