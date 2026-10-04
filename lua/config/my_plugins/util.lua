local M = {}

-- sub-word motion (used by - and _)
local pat = [[\v(_|\.|-)\zs\w|\l\zs\u|\u\zs\u\l]]

local function is_space(ch)
	return ch:match("%s") ~= nil
end

local function word_bounds(line, col1)
	local s, e = col1, col1
	while s > 1 and not is_space(line:sub(s - 1, s - 1)) do s = s - 1 end
	while e <= #line and not is_space(line:sub(e, e)) do e = e + 1 end
	return s, e - 1
end

local function match_first(str)
	local m = vim.fn.matchstrpos(str, pat)
	return m[2] ~= -1 and m[2] or nil
end

local function match_last(str)
	local last, off = nil, 0
	while true do
		local m = vim.fn.matchstrpos(str:sub(off + 1), pat)
		if m[2] == -1 then break end
		last = off + m[2]
		off = off + m[2] + 1
		if off >= #str then break end
	end
	return last
end

function M.subw(dir)
	local row, col0 = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_get_current_line()
	local col1 = col0 + 1
	local ch = line:sub(col1, col1)
	if ch == "" or is_space(ch) then
		vim.cmd("normal! " .. (dir == 1 and "w" or "b"))
		return
	end
	local ws, we = word_bounds(line, col1)
	if dir == 1 then
		local i = match_first(line:sub(col1, we))
		if i == nil then vim.cmd("normal! w"); return end
		vim.api.nvim_win_set_cursor(0, { row, col0 + i })
	else
		if col1 <= ws then vim.cmd("normal! b"); return end
		local i = match_last(line:sub(ws, col1 - 1))
		if i == nil then vim.cmd("normal! b"); return end
		vim.api.nvim_win_set_cursor(0, { row, (ws - 1) + i })
	end
end

-- smart j/k: snap to ^ if left side is whitespace
function M.smart_move(down)
	local key = tostring(vim.v.count1) .. (down and "j" or "k")
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), "n", false)
	vim.defer_fn(function()
		local _, col = unpack(vim.api.nvim_win_get_cursor(0))
		if vim.api.nvim_get_current_line():sub(1, col):match("^%s*$") then
			vim.cmd("normal! ^")
		end
	end, 0)
end

-- blank lines above/below (count-aware)
function M.blank_below()
	local n = vim.v.count ~= 0 and vim.v.count or 1
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local lines = {}
	for _ = 1, n do lines[#lines + 1] = "" end
	vim.api.nvim_buf_set_lines(0, row, row, false, lines)
end

function M.blank_above()
	local n = vim.v.count ~= 0 and vim.v.count or 1
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local lines = {}
	for _ = 1, n do lines[#lines + 1] = "" end
	vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)
	vim.api.nvim_win_set_cursor(0, { row + n, 0 })
end

-- fill current line to target column with a character
function M.fill_to_column(target_col, ch)
	local row = vim.api.nvim_win_get_cursor(0)[1] - 1
	local line = vim.api.nvim_buf_get_lines(0, row, row + 1, true)[1] or ""
	vim.api.nvim_win_set_cursor(0, { row + 1, #line })
	local count = target_col - vim.fn.virtcol(".")
	if count <= 0 then return end
	vim.cmd("normal! A" .. string.rep(ch, count))
end

-- delete all marks on the current line
function M.del_marks_on_line()
	local current_line = vim.fn.line(".")
	local marks = {}
	for line in vim.fn.execute("marks"):gmatch("[^\r\n]+") do
		local mark = line:match("^%s*([a-zA-Z])")
		local lnum = tonumber(line:match("^%s*[a-zA-Z]%s+(%d+)"))
		if mark and lnum == current_line then marks[#marks + 1] = mark end
	end
	if #marks > 0 then vim.cmd("delmarks " .. table.concat(marks, "")) end
end

-- user commands
vim.api.nvim_create_user_command("DelMarksOnLine", M.del_marks_on_line, { desc = "Delete all marks on current line" })

vim.api.nvim_create_user_command("Waqa", function()
	vim.cmd("wa")
	vim.cmd("qa")
end, { desc = "Write all and quit all" })

return M
