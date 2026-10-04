return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = { "MunifTanjim/nui.nvim" },
	opts = {
		messages = {
			enabled = true,
		},
		routes = {
			{
				filter = { event = "msg_showmode" },
				opts = { skip = true },
			},
			{
				filter = { event = "msg_show" },
				opts = { skip = true },
			},
			{
				filter = {
					event = "lsp",
					kind = "progress",
					cond = function(message)
						local client = vim.tbl_get(message.opts, "progress", "client")
						return client == "pyright"
					end,
				},
				opts = { skip = true },
			},
			{
				filter = { event = "lsp", kind = "progress", find = "Validate documents" },
				opts = { skip = true },
			},
			{
				filter = { event = "lsp", kind = "progress", find = "Publish Diagnostics" },
				opts = { skip = true },
			},
		},
		lsp = {
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
				["cmp.entry.get_documentation"] = true,
			},
		},
	},
}
