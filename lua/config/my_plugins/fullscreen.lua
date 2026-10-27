local M = {}

-- :Full [1|2]
-- mode 1: hide bufferline, lualine and line numbers
-- mode 2: hide bufferline and lualine, keep line numbers
-- same mode again (or :Full while active with no arg) turns it off

local mode = nil
local saved = {}
local group = vim.api.nvim_create_augroup("fullscreen", { clear = true })

local function set_numbers(on)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_config(win).relative == "" then
			vim.wo[win].number = on and saved.number
			vim.wo[win].relativenumber = on and saved.relativenumber
		end
	end
end

local function set_lualine(hidden)
	local ok, lualine = pcall(require, "lualine")
	if ok then lualine.hide({ unhide = not hidden }) end
end

local function disable()
	vim.api.nvim_clear_autocmds({ group = group })
	vim.o.showtabline = saved.showtabline
	vim.o.laststatus = saved.laststatus
	set_lualine(false)
	if mode == 1 then set_numbers(true) end
	mode = nil
end

local function enable(m)
	if mode == nil then
		saved.showtabline = vim.o.showtabline
		saved.laststatus = vim.o.laststatus
		saved.number = vim.wo.number
		saved.relativenumber = vim.wo.relativenumber
	elseif mode == 1 then
		set_numbers(true)
	end
	vim.api.nvim_clear_autocmds({ group = group })

	mode = m
	vim.o.showtabline = 0
	vim.o.laststatus = 0
	set_lualine(true)

	if m == 1 then
		set_numbers(false)
		-- keep numbers off in windows/buffers opened while active
		vim.api.nvim_create_autocmd({ "BufWinEnter", "WinNew" }, {
			group = group,
			callback = function() set_numbers(false) end,
		})
	end
end

function M.toggle(m)
	m = m or 1
	if mode == m then
		disable()
	else
		enable(m)
	end
end

vim.api.nvim_create_user_command("Full", function(opts)
	local m = tonumber(opts.args)
	if opts.args ~= "" and m ~= 1 and m ~= 2 then
		return vim.notify("Full: mode must be 1 or 2", vim.log.levels.ERROR)
	end
	if m == nil and mode ~= nil then return disable() end
	M.toggle(m)
end, {
	nargs = "?",
	complete = function() return { "1", "2" } end,
	desc = "Toggle fullscreen (1: no bars/numbers, 2: no bars)",
})

return M
