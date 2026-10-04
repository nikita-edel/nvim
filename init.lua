local vim = vim
------------------------------------------------------------------------
vim.g.mapleader = " "

--filter which-key warnings
local orig_notify = vim.notify
vim.notify = function(msg, level, opts)
	if msg:match("which%-key") and level == vim.log.levels.WARN then
		return
	end
	orig_notify(msg, level, opts)
end

-- undo tree
local undodir = vim.fn.stdpath("data") .. "/undo"

vim.opt.undofile = true

vim.opt.undodir = undodir

if vim.fn.isdirectory(undodir) == 0 then
	vim.fn.mkdir(undodir, "p")
end

require("config.options")
require("config.lazy")
require("config.my_plugins.util")
require("config.my_plugins.terminal")
require("config.my_plugins.guards")
require("config.keymap.my_plugins")
require("config.keymap.plugins")
require("config.keymap.vanilla")
