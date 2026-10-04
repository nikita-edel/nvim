local vim = vim
local headers = {}

local function get_git_root(dir)
	local git_dir = vim.fn.finddir(".git", dir .. ";")
	if git_dir == "" then
		return nil
	end
	local abs = vim.fn.fnamemodify(git_dir, ":p"):gsub("/$", "")
	return vim.fn.fnamemodify(abs, ":h"):gsub("/$", "")
end

local function get_display_path(dir)
	local clean = dir:gsub("/$", "")
	if clean == "" then
		return "/"
	end
	local git_root = get_git_root(clean)
	if git_root then
		local rel = clean:sub(#git_root + 2)
		if rel == "" then
			return vim.fn.fnamemodify(git_root, ":t") .. "/"
		end
		return rel .. "/"
	end
	return dir
end

local function update_header(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	if vim.bo[bufnr].filetype ~= "oil" then
		return
	end
	local dir = require("oil").get_current_dir(bufnr)
	if not dir then
		return
	end
	local text = get_display_path(dir)
	local h = headers[bufnr]

	if not h or not vim.api.nvim_buf_is_valid(h.buf) then
		local hbuf = vim.api.nvim_create_buf(false, true)
		vim.bo[hbuf].buftype = "nofile"
		vim.bo[hbuf].bufhidden = "wipe"
		vim.bo[hbuf].swapfile = false
		vim.bo[hbuf].filetype = "OilHeader"
		h = { buf = hbuf, win = -1 }
		headers[bufnr] = h

		vim.api.nvim_create_autocmd("BufHidden", {
			buffer = bufnr,
			once = true,
			callback = function()
				if h.win ~= -1 and vim.api.nvim_win_is_valid(h.win) then
					vim.api.nvim_win_close(h.win, true)
				end
				headers[bufnr] = nil
			end,
		})
	end

	vim.bo[h.buf].modifiable = true
	vim.api.nvim_buf_set_lines(h.buf, 0, -1, false, { text })
	vim.api.nvim_buf_add_highlight(h.buf, -1, "Special", 0, 0, -1)
	vim.bo[h.buf].modifiable = false
	vim.bo[h.buf].modified = false

	if h.win ~= -1 and vim.api.nvim_win_is_valid(h.win) then
		return
	end

	local oil_win = vim.fn.bufwinid(bufnr)
	if oil_win == -1 then
		return
	end
	vim.wo[oil_win].winbar = " "

	local win_pos = vim.api.nvim_win_get_position(oil_win)
	local win_width = vim.api.nvim_win_get_width(oil_win)

	h.win = vim.api.nvim_open_win(h.buf, false, {
		relative = "editor",
		width = win_width,
		height = 1,
		row = win_pos[1],
		col = win_pos[2],
		style = "minimal",
		border = "none",
		focusable = true,
		zindex = 50,
	})

	vim.api.nvim_set_option_value("winhl", "Normal:Normal", { win = h.win })
	vim.keymap.set("n", "gh", function()
		if h.win ~= -1 and vim.api.nvim_win_is_valid(h.win) then
			if vim.api.nvim_get_current_win() == h.win then
				vim.api.nvim_set_current_win(oil_win)
			else
				vim.api.nvim_set_current_win(h.win)
			end
		end
	end, { buffer = bufnr })

	vim.keymap.set("n", "gh", function()
		vim.api.nvim_set_current_win(oil_win)
	end, { buffer = h.buf })
end

return {
	"stevearc/oil.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function(_, opts)
		require("oil").setup(opts)
		vim.api.nvim_create_autocmd("User", {
			pattern = "OilEnter",
			callback = function(ev)
				vim.schedule(function()
					update_header(ev.buf)
				end)
			end,
		})
		vim.api.nvim_create_autocmd("BufEnter", {
			callback = function(ev)
				if vim.bo[ev.buf].filetype == "oil" then
					vim.schedule(function()
						update_header(ev.buf)
					end)
				end
			end,
		})
	end,
	opts = {
		default_file_explorer = true,
		columns = { "icon" },
		buf_options = {
			buflisted = false,
			bufhidden = "hide",
		},
		win_options = {
			wrap = false,
			signcolumn = "no",
			cursorcolumn = false,
			foldcolumn = "0",
			spell = false,
			list = false,
			conceallevel = 3,
			concealcursor = "nvic",
		},
		delete_to_trash = true,
		skip_confirm_for_simple_edits = true,
		prompt_save_on_select_new_entry = true,
		cleanup_delay_ms = 2000,
		lsp_file_methods = {
			enabled = true,
			timeout_ms = 1000,
			autosave_changes = false,
		},
		constrain_cursor = "editable",
		watch_for_changes = false,
		keymaps = {
			["g?"] = { "actions.show_help", mode = "n" },
			["<CR>"] = "actions.select",
			["<C-s>"] = { "actions.select", opts = { vertical = true } },
			["<C-h>"] = { "actions.select", opts = { horizontal = true } },
			["<C-t>"] = { "actions.select", opts = { tab = true } },
			["<C-p>"] = "actions.preview",
			["<C-c>"] = { "actions.close", mode = "n" },
			["<C-l>"] = "actions.refresh",
			["-"] = { "actions.parent", mode = "n" },
			["_"] = { "actions.open_cwd", mode = "n" },
			["`"] = { "actions.cd", mode = "n" },
			["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
			["gs"] = { "actions.change_sort", mode = "n" },
			["gx"] = "actions.open_external",
			["g."] = { "actions.toggle_hidden", mode = "n" },
			["g\\"] = { "actions.toggle_trash", mode = "n" },
			["q"] = { "actions.close", mode = "n" },
		},
		use_default_keymaps = true,
		view_options = {
			show_hidden = true,
			is_hidden_file = function(name, bufnr)
				return name:match("^%.") ~= nil
			end,
			is_always_hidden = function(name, bufnr)
				return name == ".." or name == ".cache" or name == ".git"
			end,
			natural_order = "fast",
			case_insensitive = false,
			sort = {
				{ "type", "asc" },
				{ "name", "asc" },
			},
		},
		float = {
			padding = 2,
			max_width = 0,
			max_height = 0,
			border = "rounded",
			win_options = { winblend = 0 },
		},
		preview_win = {
			update_on_cursor_moved = true,
			preview_method = "fast_scratch",
			disable_preview = function(filename)
				return false
			end,
			win_options = {},
		},
		confirmation = {
			max_width = 0.9,
			min_width = { 40, 0.4 },
			width = nil,
			max_height = 0.9,
			min_height = { 5, 0.1 },
			height = nil,
			border = "rounded",
			win_options = { winblend = 0 },
		},
		progress = {
			max_width = 0.9,
			min_width = { 40, 0.4 },
			width = nil,
			max_height = { 10, 0.9 },
			min_height = { 5, 0.1 },
			height = nil,
			border = "rounded",
			minimized_border = "none",
			win_options = { winblend = 0 },
		},
		ssh = { border = "rounded" },
		keymaps_help = { border = "rounded" },
	},
}
