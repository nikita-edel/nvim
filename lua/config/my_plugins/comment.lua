local function get_ts_root(bufnr)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then return nil end
	local tree = parser:parse()[1]
	return tree and tree:root()
end

local function is_comment_node(node)
	if not node then return false end
	local t = node:type()
	return type(t) == "string" and t:find("comment") ~= nil
end

local function comment_node_at_pos(bufnr, row0, col0)
	local node = vim.treesitter.get_node({ bufnr = bufnr, pos = { row0, col0 } })
	while node and not is_comment_node(node) do node = node:parent() end
	if not node then return nil end
	while node:parent() and is_comment_node(node:parent()) do node = node:parent() end
	return node
end

local function overlaps(a_sr, a_sc, a_er, a_ec, b_sr, b_sc, b_er, b_ec)
	if a_er < b_sr or (a_er == b_sr and a_ec <= b_sc) then return false end
	if b_er < a_sr or (b_er == a_sr and b_ec <= a_sc) then return false end
	return true
end

local function collect_comment_nodes(bufnr, sr, sc, er, ec)
	local root = get_ts_root(bufnr)
	if not root then return nil end
	local out, stack = {}, { root }
	while #stack > 0 do
		local node = table.remove(stack)
		local nsr, nsc, ner, nec = node:range()
		if overlaps(nsr, nsc, ner, nec, sr, sc, er, ec) then
			if is_comment_node(node) then
				out[#out + 1] = node
			else
				for i = 0, node:child_count() - 1 do stack[#stack + 1] = node:child(i) end
			end
		end
	end
	table.sort(out, function(a, b)
		local asr, asc, aer, aec = a:range()
		local bsr, bsc, ber, bec = b:range()
		if asr ~= bsr then return asr > bsr end
		if asc ~= bsc then return asc > bsc end
		if aer ~= ber then return aer > ber end
		return aec > bec
	end)
	return out
end

local function clamp_pos(bufnr, row0, col0)
	row0 = math.max(0, math.min(row0, vim.api.nvim_buf_line_count(bufnr) - 1))
	local line = vim.api.nvim_buf_get_lines(bufnr, row0, row0 + 1, false)[1] or ""
	return row0, math.max(0, math.min(col0, #line))
end

local function buf_delete_text(bufnr, sr, sc, er, ec)
	sr, sc = clamp_pos(bufnr, sr, sc)
	local lc = vim.api.nvim_buf_line_count(bufnr)
	if er >= lc then
		er = lc - 1
		ec = #(vim.api.nvim_buf_get_lines(bufnr, er, er + 1, false)[1] or "")
	end
	er, ec = clamp_pos(bufnr, er, ec)
	if er < sr or (er == sr and ec < sc) then sr, er, sc, ec = er, sr, ec, sc end
	if er == sr and ec == sc then return end
	vim.api.nvim_buf_set_text(bufnr, sr, sc, er, ec, { "" })
end

local function visual_range(bufnr, line1, line2)
	if vim.fn.visualmode() == "V" then return line1 - 1, 0, line2, 0 end
	local p1, p2 = vim.fn.getpos("'<"), vim.fn.getpos("'>")
	local sr1, sc1, er1, ec1 = p1[2], p1[3], p2[2], p2[3]
	if er1 < sr1 or (er1 == sr1 and ec1 < sc1) then sr1, er1, sc1, ec1 = er1, sr1, ec1, sc1 end
	local er0 = er1 - 1
	local endline = vim.api.nvim_buf_get_lines(bufnr, er0, er0 + 1, false)[1] or ""
	local ec_excl = math.max(0, math.min(ec1, #endline))
	local sr0, sc0 = clamp_pos(bufnr, sr1 - 1, sc1 - 1)
	er0, ec_excl = clamp_pos(bufnr, er0, ec_excl)
	return sr0, sc0, er0, ec_excl
end

local function parse_cstring(cs)
	if type(cs) ~= "string" or cs == "" then return nil end
	local s, e = cs:find("%%s")
	if not s then return nil end
	return cs:sub(1, s - 1), cs:sub(e + 1)
end

local function get_comment_strings(bufnr)
	local ok, ftmod = pcall(require, "Comment.ft")
	if not ok then return nil end
	local spec = ftmod.get(vim.bo[bufnr].filetype)
	if type(spec) == "string" then return spec, nil end
	if type(spec) == "table" then return spec[1], spec[2] end
	return nil
end

local function ltrim(s)
	local i = 1
	while i <= #s and (s:sub(i, i) == " " or s:sub(i, i) == "\t") do i = i + 1 end
	return i - 1
end

local function rtrim(s)
	local i = #s
	while i >= 1 and (s:sub(i, i) == " " or s:sub(i, i) == "\t") do i = i - 1 end
	return #s - i
end

local function uncomment_line(line, open, close)
	local li = ltrim(line)
	local head, body = line:sub(1, li), line:sub(li + 1)
	if open ~= "" and body:sub(1, #open) == open then
		body = body:sub(#open + 1)
		if body:sub(1, 1) == " " or body:sub(1, 1) == "\t" then body = body:sub(2) end
	end
	if close ~= "" then
		local rt = rtrim(body)
		local core = body:sub(1, #body - rt)
		if #core >= #close and core:sub(-#close) == close then
			core = core:sub(1, #core - #close):gsub("[ \t]+$", "")
			body = core .. body:sub(#body - rt + 1)
		end
	end
	return head .. body
end

local function uncomment_block(text, open, close)
	local li, ri = ltrim(text), rtrim(text)
	local lead, core, tail = text:sub(1, li), text:sub(li + 1, #text - ri), text:sub(#text - ri + 1)
	if open ~= "" and core:sub(1, #open) == open then core = core:sub(#open + 1):gsub("^[ \t]+", "") end
	if close ~= "" and #core >= #close and core:sub(-#close) == close then
		core = core:sub(1, #core - #close):gsub("[ \t]+$", "")
	end
	return lead .. core .. tail
end

local function uncomment_node(bufnr, node)
	local sr, sc, er, ec = node:range()
	local lines = vim.api.nvim_buf_get_text(bufnr, sr, sc, er, ec, {})
	local text = table.concat(lines, "\n")
	local line_cs, block_cs = get_comment_strings(bufnr)
	if not line_cs and not block_cs then
		error("Uncom requires Comment.nvim ft config for this filetype")
	end
	local line_open, line_close = line_cs and parse_cstring(line_cs)
	local block_open, block_close = block_cs and parse_cstring(block_cs)
	if block_open and block_close then
		local tlead = text:gsub("^[ \t]+", "")
		if block_open ~= "" and tlead:sub(1, #block_open) == block_open then
			local tr = text:gsub("[ \t]+$", "")
			if block_close == "" or (#tr >= #block_close and tr:sub(-#block_close) == block_close) then
				local new_lines = vim.split(uncomment_block(text, block_open, block_close), "\n", { plain = true })
				vim.api.nvim_buf_set_text(bufnr, sr, sc, er, ec, new_lines)
				return
			end
		end
	end
	if not line_open then return end
	for i = 1, #lines do lines[i] = uncomment_line(lines[i], line_open, line_close or "") end
	vim.api.nvim_buf_set_text(bufnr, sr, sc, er, ec, lines)
end

local M = {}

function M.delete_under_cursor(bufnr)
	local row1, col0 = unpack(vim.api.nvim_win_get_cursor(0))
	local row0 = row1 - 1
	local node = comment_node_at_pos(bufnr, row0, col0)
	if node then
		local sr, sc, er, ec = node:range()
		if er > sr then buf_delete_text(bufnr, sr, sc, er, ec)
		else vim.api.nvim_buf_set_lines(bufnr, sr, sr + 1, false, {}) end
		return
	end
	local nodes = collect_comment_nodes(bufnr, row0, 0, row0 + 1, 0)
	if nodes and #nodes > 0 then
		vim.api.nvim_buf_set_lines(bufnr, row0, row0 + 1, false, {})
	end
end

function M.delete_in_visual(bufnr, line1, line2)
	local sr, sc, er, ec = visual_range(bufnr, line1, line2)
	local nodes = collect_comment_nodes(bufnr, sr, sc, er, ec)
	if not nodes then error("Delcom requires Tree-sitter for this buffer") end
	for _, node in ipairs(nodes) do
		local nsr, nsc, ner, nec = node:range()
		if ner == nsr then
			local line = vim.api.nvim_buf_get_lines(bufnr, nsr, nsr + 1, false)[1] or ""
			local rest = line:sub(1, nsc) .. line:sub(nec + 1)
			if rest:match("^%s*$") then vim.api.nvim_buf_set_lines(bufnr, nsr, nsr + 1, false, {})
			else buf_delete_text(bufnr, nsr, nsc, ner, nec) end
		else
			buf_delete_text(bufnr, nsr, nsc, ner, nec)
		end
	end
end

function M.uncomment_under_cursor(bufnr)
	local row1, col0 = unpack(vim.api.nvim_win_get_cursor(0))
	local node = comment_node_at_pos(bufnr, row1 - 1, col0)
	if node then uncomment_node(bufnr, node) end
end

function M.uncomment_in_visual(bufnr, line1, line2)
	local sr, sc, er, ec = visual_range(bufnr, line1, line2)
	local nodes = collect_comment_nodes(bufnr, sr, sc, er, ec)
	if not nodes then error("Uncom requires Tree-sitter for this buffer") end
	for _, node in ipairs(nodes) do uncomment_node(bufnr, node) end
end

function M.uncomment_or_toggle(bufnr)
	local row1, col0 = unpack(vim.api.nvim_win_get_cursor(0))
	local node = comment_node_at_pos(bufnr, row1 - 1, col0)
	if node then
		uncomment_node(bufnr, node)
	else
		require("Comment.api").toggle.linewise.current()
	end
end

vim.api.nvim_create_user_command("Delcom", function(opts)
	local bufnr = vim.api.nvim_get_current_buf()
	if opts.range > 0 then M.delete_in_visual(bufnr, opts.line1, opts.line2)
	else M.delete_under_cursor(bufnr) end
end, { range = true })

vim.api.nvim_create_user_command("Uncom", function(opts)
	local bufnr = vim.api.nvim_get_current_buf()
	if opts.range > 0 then M.uncomment_in_visual(bufnr, opts.line1, opts.line2)
	else M.uncomment_under_cursor(bufnr) end
end, { range = true })

vim.api.nvim_create_user_command("Uncoms", function(opts)
	local bufnr = vim.api.nvim_get_current_buf()
	if opts.range > 0 then M.uncomment_in_visual(bufnr, opts.line1, opts.line2)
	else M.uncomment_or_toggle(bufnr) end
end, { range = true })

return M
