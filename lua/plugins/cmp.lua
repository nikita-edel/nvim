return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = { "hrsh7th/cmp-nvim-lsp" },
	config = function()
		local cmp = require("cmp")
		cmp.setup({
			mapping = {
				["<Tab>"] = cmp.mapping.select_next_item(),
				["<S-Tab>"] = cmp.mapping.select_prev_item(),
				["<CR>"] = cmp.mapping.confirm({ select = true }),
			},
			sources = {
				{ name = "nvim_lsp" },
			},
			performance = {
				max_view_entries = 10,
			},
		})
	end,
}
