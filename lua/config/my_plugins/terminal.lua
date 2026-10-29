local state = { buf = nil, win = nil }

local function pick_shell()
	if vim.fn.has("win32") == 1 then
		if vim.fn.executable("pwsh") == 1 then
			return { "pwsh", "-NoLogo" }
		end
		-- Store-installed pwsh is an app execution alias that nvim refuses to spawn directly
		if vim.uv.fs_lstat(vim.env.LOCALAPPDATA .. "\\Microsoft\\WindowsApps\\pwsh.exe") then
			return { "cmd.exe", "/c", "pwsh", "-NoLogo" }
		end
		if vim.fn.executable("powershell") == 1 then
			return { "powershell", "-NoLogo" }
		end
	end
	return vim.o.shell
end

local shell = pick_shell()

local function win_valid(win)
	return win and vim.api.nvim_win_is_valid(win)
end

local function buf_valid(buf)
	return buf and vim.api.nvim_buf_is_valid(buf)
end

local function set_term_keymaps(buf)
	local o = { buffer = buf, silent = true, noremap = true }
	-- first <Esc> goes to the shell immediately; a second one within 300ms leaves terminal mode
	local last_esc = 0
	vim.keymap.set("t", "<Esc>", function()
		local now = vim.uv.hrtime()
		if now - last_esc < 300e6 then
			last_esc = 0
			return "<C-\\><C-n>"
		end
		last_esc = now
		return "<Esc>"
	end, vim.tbl_extend("force", o, { expr = true }))
	--[[ vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", o)
	vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", o)
	vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", o)
	vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", o) ]]
end

local function attach_termclose(buf)
	if not buf_valid(buf) then return end
	vim.api.nvim_create_autocmd("TermClose", {
		group = vim.api.nvim_create_augroup("FloatTermClose_" .. buf, { clear = true }),
		buffer = buf,
		callback = function()
			if win_valid(state.win) then
				pcall(vim.api.nvim_win_close, state.win, true)
			end
			state.win = nil
		end,
	})
end

local function open_float(buf)
	buf = buf_valid(buf) and buf or vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = vim.o.columns,
		height = vim.o.lines,
		col = 0,
		row = 0,
		style = "minimal",
		border = "rounded",
	})
	pcall(vim.api.nvim_win_set_option, win, "winblend", 0)
	pcall(vim.api.nvim_win_set_option, win, "cursorline", false)
	return buf, win
end

local function ensure_terminal(buf)
	if vim.bo[buf].buftype == "terminal" then
		set_term_keymaps(buf)
		attach_termclose(buf)
		return buf
	end
	local cur_win = vim.api.nvim_get_current_win()
	if vim.api.nvim_win_get_buf(cur_win) ~= buf then
		vim.api.nvim_win_set_buf(cur_win, buf)
	end
	vim.fn.termopen(shell)
	local term_buf = vim.api.nvim_win_get_buf(cur_win)
	set_term_keymaps(term_buf)
	attach_termclose(term_buf)
	return term_buf
end

local M = {}

function M.toggle()
	if not win_valid(state.win) then
		state.buf, state.win = open_float(state.buf)
		state.buf = ensure_terminal(state.buf)
		vim.cmd("startinsert")
	else
		vim.api.nvim_win_hide(state.win)
		state.win = nil
	end
end

vim.api.nvim_create_user_command("Floaterminal", M.toggle, {})

return M
