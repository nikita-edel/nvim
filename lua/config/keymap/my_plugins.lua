local map = vim.keymap.set

-- terminal
map("n", "<leader>t", function()
	require("config.my_plugins.terminal").toggle()
end, { desc = "Toggle terminal", silent = true })

-- comment
map("n", "<leader>/", "<cmd>Uncoms<CR>", { desc = "Uncomment/toggle", noremap = true, silent = true })

map("x", "<leader>/s", "<Esc><cmd>lua require('Comment.api').toggle.blockwise(vim.fn.visualmode())<CR>", { desc = "Toggle block comment", noremap = true, silent = true })

map("x", "<leader>/a", function()
	local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
	vim.api.nvim_feedkeys(esc, "x", false)
	local srow, erow = vim.fn.line("'<"), vim.fn.line("'>")
	local cur = vim.api.nvim_win_get_cursor(0)
	local api = require("Comment.api")
	for l = srow, erow do
		vim.api.nvim_win_set_cursor(0, { l, 0 })
		api.toggle.linewise.current()
	end
	vim.api.nvim_win_set_cursor(0, cur)
end, { desc = "Toggle comment per line", noremap = true, silent = true })
