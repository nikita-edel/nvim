local function abs(path)
	return vim.fn.fnamemodify(path, ":p"):gsub("[/\\]+$", "")
end

local function git_root(dir)
	local result = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
	if vim.v.shell_error == 0 and result[1] and result[1] ~= "" then
		return abs(result[1])
	end
	return abs(vim.fn.getcwd())
end

local function is_under(path, root)
	return path:sub(1, #root + 1) == root .. "/"
end

local function guard_name(rel_path)
	rel_path = rel_path:gsub("\\", "/"):gsub("%.[^./]+$", "")
	local g = rel_path:gsub("[^A-Za-z0-9]+", "_"):gsub("^_+", ""):gsub("_+$", ""):upper()
	return (g == "" and "HEADER" or g) .. "_H"
end

local M = {}

function M.add(root_start, force_visual)
	local file = vim.api.nvim_buf_get_name(0)
	if file == "" then
		vim.notify("buffer has no file name", vim.log.levels.ERROR)
		return
	end

	file = abs(file)
	local base = git_root(abs(vim.fn.fnamemodify(file, ":h")))
	local logical_root = base
	if root_start and root_start ~= "" then
		local clean = root_start:gsub("\\", "/"):gsub("^/+", ""):gsub("/+$", "")
		logical_root = abs(base .. "/" .. clean)
	end

	if not is_under(file, logical_root) then
		vim.notify("file is not under root: " .. logical_root, vim.log.levels.ERROR)
		return
	end

	local guard = guard_name(file:sub(#logical_root + 2))
	local mode = vim.fn.mode(true)
	local first = mode:sub(1, 1)
	local use_visual = force_visual or first == "v" or first == "V" or first == string.char(22)

	local start_line, end_line
	if use_visual then
		start_line = math.min(vim.fn.getpos("'<")[2], vim.fn.getpos("'>")[2])
		end_line = math.max(vim.fn.getpos("'<")[2], vim.fn.getpos("'>")[2])
	else
		start_line = 1
		end_line = vim.api.nvim_buf_line_count(0)
	end

	local before = { "#ifndef " .. guard, "#define " .. guard, "" }
	local after = { "", "#endif" }
	vim.api.nvim_buf_set_lines(0, start_line - 1, start_line - 1, false, before)
	vim.api.nvim_buf_set_lines(0, end_line + #before, end_line + #before, false, after)

	if first == "i" then vim.cmd("startinsert") end
end

function M.remove()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local first = 1
	while first <= #lines and lines[first]:match("^%s*$") do first = first + 1 end
	if first > #lines then
		vim.notify("buffer is empty", vim.log.levels.ERROR)
		return false
	end

	local guard = lines[first]:match("^%s*#%s*ifndef%s+([A-Za-z_][A-Za-z0-9_]*)%s*$")
	if not guard then
		vim.notify("no header guard found", vim.log.levels.ERROR)
		return false
	end

	local def = first + 1
	while def <= #lines and lines[def]:match("^%s*$") do def = def + 1 end
	if lines[def] and lines[def]:match("^%s*#%s*define%s+([A-Za-z_][A-Za-z0-9_]*)") ~= guard then
		vim.notify("#define does not match #ifndef", vim.log.levels.ERROR)
		return false
	end

	local depth, closing = 0, nil
	for i = first, #lines do
		local d = lines[i]:match("^%s*#%s*([A-Za-z]+)")
		if d == "if" or d == "ifdef" or d == "ifndef" then
			depth = depth + 1
		elseif d == "endif" then
			depth = depth - 1
			if depth == 0 then closing = i; break end
		end
	end

	if not closing then
		vim.notify("no matching #endif", vim.log.levels.ERROR)
		return false
	end

	local last = #lines
	while last > closing and lines[last]:match("^%s*$") do last = last - 1 end
	if last ~= closing then
		vim.notify("guard does not cover the entire file", vim.log.levels.ERROR)
		return false
	end

	local open_end = def
	if lines[open_end + 1] and lines[open_end + 1]:match("^%s*$") then open_end = open_end + 1 end
	local close_start = closing
	if close_start - 1 > open_end and lines[close_start - 1]:match("^%s*$") then close_start = close_start - 1 end

	local result = {}
	for i, line in ipairs(lines) do
		if not (i >= first and i <= open_end) and not (i >= close_start and i <= closing) then
			result[#result + 1] = line
		end
	end
	vim.api.nvim_buf_set_lines(0, 0, -1, false, result)
	return true
end

vim.api.nvim_create_user_command("Guards", function(opts)
	M.add(opts.args, opts.range > 0)
end, { nargs = "?", range = true })

vim.api.nvim_create_user_command("GuardsRm", function()
	M.remove()
end, {})

vim.api.nvim_create_user_command("GuardsRp", function(opts)
	if M.remove() then M.add(opts.args, opts.range > 0) end
end, { nargs = "?", range = true })

return M
