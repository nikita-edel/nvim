local map = vim.keymap.set

-- bufferline
map("n", "H", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer", noremap = true, silent = true })
map("n", "L", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer", noremap = true, silent = true })
-- Also where H and L do something else (texel documents scroll sideways).
map("n", "<leader>H", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer", noremap = true, silent = true })
map("n", "<leader>L", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer", noremap = true, silent = true })

-- oil

local function oil_open_background()
	local oil = require("oil")
	local dir = oil.get_current_dir()
	if not dir then return end
	local first, last = vim.fn.line("."), vim.fn.line(".")
	if vim.fn.mode():match("^[vV\22]") then
		first, last = math.min(vim.fn.line("v"), last), math.max(vim.fn.line("v"), last)
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
	end
	for lnum = first, last do
		local entry = oil.get_entry_on_line(0, lnum)
		if entry and entry.type ~= "directory" then
			vim.cmd("badd " .. vim.fn.fnameescape(dir .. entry.name))
		end
	end
end

local oil_filter = nil
local function oil_set_filter(pattern)
	local view_options = require("oil.config").view_options
	if not view_options._orig_is_always_hidden then
		view_options._orig_is_always_hidden = view_options.is_always_hidden
		view_options.is_always_hidden = function(name, bufnr)
			if view_options._orig_is_always_hidden(name, bufnr) then return true end
			return oil_filter ~= nil and name ~= ".." and not oil_filter:match_str(name)
		end
	end
	if pattern == nil or pattern == "" then
		oil_filter = nil
	else
		local ok, re = pcall(vim.regex, pattern:find("[*?]") and vim.fn.glob2regpat(pattern) or pattern)
		if not ok then return vim.notify("Oil filter: invalid pattern " .. pattern, vim.log.levels.ERROR) end
		oil_filter = re
	end
	require("oil.view").rerender_all_oil_buffers({ refetch = false })
end

local oil_show_size = false
local function oil_toggle_size()
	oil_show_size = not oil_show_size
	require("oil").set_columns(oil_show_size and { "icon", "size" } or { "icon" })
end

-- tcd, then bring the shells along: the float terminal right away, the shell nvim was
-- started from on exit (the nvim wrapper in the pwsh profile sets NVIM_CD_FILE)
local function oil_cd()
	local dir = require("oil").get_current_dir()
	if not dir then return end
	require("oil.actions").cd.callback({ scope = "tab" })
	require("config.my_plugins.terminal").cd(dir)
	if vim.env.NVIM_CD_FILE then vim.fn.writefile({ dir }, vim.env.NVIM_CD_FILE) end
end

map("n", "<leader>e", "<cmd>Oil<cr>", { desc = "Open Oil", noremap = true, silent = true })
vim.api.nvim_create_autocmd("FileType", {
	pattern = "oil",
	callback = function(ev)
		local actions = require("oil.actions")
		local function omap(mode, lhs, rhs, desc)
			map(mode, lhs, rhs, { buffer = ev.buf, desc = desc, noremap = true, silent = true })
		end

		omap("n", "g?", function() require("which-key").show({ global = false }) end, "Oil: Show keymaps")
		omap("", "<CR>", actions.select.callback, "Oil: Open entry")
		omap("", "<leader>w", actions.preview.callback, "Oil: Preview entry")
		omap("", "<>", actions.refresh.callback, "Oil: Refresh")

		omap("n", "-", actions.parent.callback, "Oil: Parent directory")

		omap("n", "~", oil_cd, "Oil: cd nvim and shells to current directory")

		omap("n", "gs", oil_toggle_size, "Oil: Toggle file sizes")

		omap("n", "q", actions.close.callback, "Oil: Close")

		omap("", "<S-CR>", oil_open_background, "Oil: Open entry as buffer, stay in oil")

		omap("n", "gf", function()
			vim.ui.input({ prompt = "Oil filter (glob or regex, empty clears): " }, function(input)
				if input then oil_set_filter(input) end
			end)
		end, "Oil: Filter entries")

		omap("n", "gF", function() oil_set_filter(nil) end, "Oil: Clear filter")
	end,
})

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
