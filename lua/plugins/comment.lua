return {
	"numToStr/Comment.nvim",
	event = "VeryLazy",
	config = function()
		local ft = require("Comment.ft")
		ft.set("ps1", { "#%s", "<#%s#>" })
		ft.set("dosbatch", "::%s")
		require("Comment").setup({
			ignore = "^$",
			-- nvim 0.12 get_parser returns nil instead of throwing, which breaks
			-- Comment.nvim for every filetype without a treesitter parser
			pre_hook = function(ctx)
				if vim.treesitter.get_parser(0, nil, { error = false }) then return end
				return ft.get(vim.bo.filetype, ctx.ctype) or ft.get(vim.bo.filetype, 1) or vim.bo.commentstring
			end,
		})
		require("config.my_plugins.comment")
	end,
}
