local map = vim.keymap.set

-- bufferline
map("n", "H", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer", noremap = true, silent = true })
map("n", "L", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer", noremap = true, silent = true })

-- oil
map("n", "<leader>e", "<cmd>Oil<cr>", { desc = "Open Oil", noremap = true, silent = true })

-- telescope
local function telescope_cwd()
	local scope_file = table.concat({ vim.fn.stdpath("state"), "telescope_scope" }, package.config:sub(1, 1))
	local is_local = vim.fn.filereadable(scope_file) == 1 and vim.fn.readfile(scope_file)[1] == "local"
	local file = vim.api.nvim_buf_get_name(0)
	local dir = file ~= "" and vim.fn.fnamemodify(file, ":p:h") or vim.fn.getcwd()
	if is_local then return dir end
	local root = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })[1]
	if vim.v.shell_error == 0 and root and root ~= "" then return vim.trim(root) end
	return dir
end

map("n", "<leader>gf", function()
	require("telescope.builtin").current_buffer_fuzzy_find({
		sorting_strategy = "ascending",
		layout_config = { prompt_position = "top" },
	})
end, { desc = "Fzf in current file", noremap = true, silent = true })

map("n", "<leader>gg", function()
	require("telescope.builtin").live_grep({ cwd = telescope_cwd() })
end, { desc = "Live grep", noremap = true, silent = true })

map("n", "<leader>gh", function()
	require("telescope.builtin").find_files({
		cwd = telescope_cwd(),
		hidden = true,
		find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
	})
end, { desc = "Find files", noremap = true, silent = true })

-- LSP
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition", noremap = true, silent = true })
map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration", noremap = true, silent = true })
map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation", noremap = true, silent = true })
map("n", "gr", vim.lsp.buf.references, { desc = "Go to references", noremap = true, silent = true })
map("n", "K", vim.lsp.buf.hover, { desc = "Hover info", noremap = true, silent = true })
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol", noremap = true, silent = true })
map("n", "<leader>D", vim.diagnostic.open_float, { desc = "Hover diagnostic", noremap = true, silent = true })


-- diagnostics toggles
local diag_vtext = true
map("n", "<leader>uv", function()
	diag_vtext = not diag_vtext
	vim.diagnostic.config({ virtual_text = diag_vtext })
end, { desc = "Toggle virtual text diagnostics" })

local diag_all = true
map("n", "<leader>ua", function()
	diag_all = not diag_all
	vim.diagnostic.config({
		virtual_text = diag_all,
		signs = diag_all,
		underline = diag_all,
		update_in_insert = diag_all,
	})
end, { desc = "Toggle all diagnostics" })

-- marks
map("n", "dm", ":DelMarksOnLine<CR>", { desc = "Delete marks on line", silent = true })
map("n", "dM", "<cmd>delmarks!<CR>", { desc = "Delete all marks", silent = true })


-- buffer close (bufferline)
map("n", "<leader>c", function()
	local cur = vim.api.nvim_get_current_buf()
	local next = vim.fn.bufnr("#")
	if not vim.api.nvim_buf_is_valid(next) or not vim.api.nvim_buf_is_loaded(next) then
		for _, b in ipairs(vim.api.nvim_list_bufs()) do
			if b ~= cur and vim.api.nvim_buf_get_option(b, "buflisted") then
				next = b
				break
			end
		end
	end
	if vim.api.nvim_buf_is_valid(next) then vim.cmd("buffer " .. next) end
	vim.cmd("bdelete " .. cur)
end, { desc = "Close buffer", noremap = true, silent = true })

