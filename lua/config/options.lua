local vim = vim
local opt = vim.opt


vim.o.signcolumn = "number"
opt.number = true
opt.relativenumber = true
opt.expandtab = false
opt.shiftwidth = 4
opt.softtabstop = 4
opt.tabstop = 4
opt.wrap = false
opt.cursorline = true
opt.termguicolors = true
opt.clipboard = "unnamedplus"
opt.splitbelow = true
opt.splitright = true
opt.fixendofline = true
vim.g.editorconfig = true

opt.autoindent = true

vim.diagnostic.config({
	virtual_text = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.INFO] = "",
			[vim.diagnostic.severity.HINT] = "",
		},
		numhl = {
			[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
			[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
			[vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
			[vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
		},
	},
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})
