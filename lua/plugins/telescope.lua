local vim = vim

local telescope_scope_file = table.concat({
	vim.fn.stdpath("state"),
	"telescope_scope",
}, package.config:sub(1, 1))

local function read_telescope_local()
	if vim.fn.filereadable(telescope_scope_file) ~= 1 then
		return false
	end
	local lines = vim.fn.readfile(telescope_scope_file)
	return lines[1] == "local"
end

local function write_telescope_local(value)
	vim.fn.mkdir(vim.fn.stdpath("state"), "p")
	if value then
		vim.fn.writefile({ "local" }, telescope_scope_file)
	else
		vim.fn.writefile({ "global" }, telescope_scope_file)
	end
end

local telescope_local = read_telescope_local()

local function current_dir()
	local current_file = vim.api.nvim_buf_get_name(0)
	if current_file ~= "" then
		return vim.fn.fnamemodify(current_file, ":p:h")
	end
	return vim.fn.getcwd()
end

local function git_root(dir)
	local root = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })[1]
	if root ~= nil then
		root = vim.trim(root)
	end
	if vim.v.shell_error == 0 and root ~= nil and root ~= "" then
		return root
	end
	return nil
end

local function telescope_cwd()
	local dir = current_dir()
	if telescope_local then
		return dir
	end
	return git_root(dir) or dir
end

local function toggle_telescope_scope()
	telescope_local = not telescope_local
	write_telescope_local(telescope_local)
	if telescope_local then
		vim.notify("Telescope scope: local directory")
	else
		vim.notify("Telescope scope: global")
	end
end

local function notify_telescope_scope()
	if telescope_local then
		vim.notify("Telescope scope: local directory")
	else
		vim.notify("Telescope scope: global")
	end
end

return {
	"nvim-telescope/telescope.nvim",
	cmd = "Telescope",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
	},
	init = function()
		vim.api.nvim_create_user_command("TelS", toggle_telescope_scope, {})
		vim.api.nvim_create_user_command("TelSi", notify_telescope_scope, {})
	end,
	keys = {
		{
			"<leader>gf",
			function()
				require("telescope.builtin").current_buffer_fuzzy_find({
					sorting_strategy = "ascending",
					layout_config = { prompt_position = "top" },
				})
			end,
			mode = "n",
			desc = "fzf in curr file",
			silent = true,
		},
		{
			"<leader>gh",
			function()
				require("telescope.builtin").find_files({
					cwd = telescope_cwd(),
					hidden = true,
					find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
				})
			end,
			mode = "n",
			desc = "find filenames",
			silent = true,
		},
	},
	config = function()
		local telescope = require("telescope")
		telescope.setup({
			defaults = {
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"--hidden",
					"--glob=!.git/*",
				},
			},
			pickers = {
				current_buffer_fuzzy_find = {
					previewer = false,
				},
			},
			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
			},
		})
		pcall(telescope.load_extension, "fzf")
	end,
}
