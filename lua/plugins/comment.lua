return {
	"numToStr/Comment.nvim",
	event = "VeryLazy",
	config = function()
		require("Comment").setup({ ignore = "^$" })
		require("config.my_plugins.comment")
	end,
}
