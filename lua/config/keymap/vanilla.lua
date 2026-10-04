local map = vim.keymap.set
local u = require("config.my_plugins.util")

-- clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { noremap = true, silent = true })

-- sub-word motion
map({ "n", "x", "o" }, "-", function() u.subw(1) end, { desc = "Sub-word forward", silent = true })
map({ "n", "x", "o" }, "_", function() u.subw(-1) end, { desc = "Sub-word backward", silent = true })

-- smart j/k
map("n", "j", function() u.smart_move(true) end, { desc = "Move down (smart)", noremap = true, silent = true })
map("n", "k", function() u.smart_move(false) end, { desc = "Move up (smart)", noremap = true, silent = true })

-- visual indent
-- map("v", "<Tab>", ">gv", { desc = "Indent right", noremap = true, silent = true })
-- map("v", "<S-Tab>", "<gv", { desc = "Indent left", noremap = true, silent = true })

-- TODO: better binds for this
-- system clipboard
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard", noremap = true, silent = true })
map({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from system clipboard", noremap = true, silent = true })

-- write all and quit all
map("n", "<leader>q", "<cmd>Waqa<cr>", { desc = "Write all and quit all", noremap = true, silent = true })

-- toggle relative/absolute line numbers
map("n", "<leader>un", function()
	local num = vim.wo.number
	local rel = vim.wo.relativenumber
	if num and rel then
		vim.wo.relativenumber = false
	elseif num and not rel then
		vim.wo.relativenumber = true
	else
		vim.wo.number = true
		vim.wo.relativenumber = false
	end
end, { desc = "Toggle relative/absolute line numbers" })

-- blank lines
map("n", "z", u.blank_below, { desc = "Add blank line below", silent = true })
map("n", "Z", u.blank_above, { desc = "Add blank line above", silent = true })

