return {
	"mg979/vim-visual-multi",
	branch = "master",
	init = function()
		vim.g.VM_default_mappings = 1
		vim.g.VM_maps = {
			["Find Under"] = "<C-n>",
			["Find Subword Under"] = "<C-n>",
			["Select All"] = "<C-l>",
			["Skip Region"] = "n",
			["Add Cursor Down"] = "<C-j>",
			["Add Cursor Up"] = "<C-k>",
		}
	end,
}
