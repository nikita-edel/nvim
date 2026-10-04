return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local function git_project_name()
			local bufname = vim.api.nvim_buf_get_name(0)
			local start = bufname ~= "" and vim.fs.dirname(bufname) or vim.uv.cwd()
			if start == nil then
				return ""
			end
			local root = vim.fs.root(start, ".git")
			if root == nil then
				return vim.fn.fnamemodify(start, ":t")
			end
			return vim.fn.fnamemodify(root, ":t")
		end

		require("lualine").setup({
			options = {
				theme = "auto",
				disabled_filetypes = {
					statusline = { "OilHeader" },
					winbar = { "OilHeader" },
				},
			},
			sections = {
				lualine_c = { git_project_name },
			},
		})
	end,
}
