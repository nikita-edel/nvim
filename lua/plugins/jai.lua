-- Jai support
--   jai.vim:         filetype detection + indentation (+ fallback regex syntax)
--   tree-sitter-jai: tree-sitter highlighting, built natively (no nvim-treesitter needed)

-- tree-sitter-jai still uses the old nvim-treesitter capture names, which
-- current colorschemes don't style. Link them to the new names (jai only).
local legacy_captures = {
	["@include"] = "@keyword.import",
	["@conditional"] = "@keyword.conditional",
	["@conditional.ternary"] = "@keyword.conditional.ternary",
	["@repeat"] = "@keyword.repeat",
	["@field"] = "@variable.member",
	["@namespace"] = "@module",
	["@parameter"] = "@variable.parameter",
}

local function link_legacy_captures()
	for old, new in pairs(legacy_captures) do
		vim.api.nvim_set_hl(0, old .. ".jai", { link = new, default = true })
	end
end

return {
	{ "rluba/jai.vim", lazy = false },
	{
		"constantitus/tree-sitter-jai",
		lazy = false,
		-- Runs on install/update: compile the parser and lay the queries out
		-- where Neovim looks for them (<rtp>/parser/jai.so, <rtp>/queries/jai/).
		build = function(plugin)
			local dir = plugin.dir
			vim.fn.mkdir(dir .. "/parser", "p")
			vim.fn.mkdir(dir .. "/queries/jai", "p")
			local res = vim.system({
				"cc", "-O2", "-shared", "-fPIC", "-Isrc",
				"src/parser.c", "src/scanner.c",
				"-o", "parser/jai.so",
			}, { cwd = dir }):wait()
			if res.code ~= 0 then
				error("tree-sitter-jai build failed:\n" .. res.stderr)
			end
			for _, f in ipairs(vim.fn.glob(dir .. "/queries/*.scm", false, true)) do
				vim.uv.fs_copyfile(f, dir .. "/queries/jai/" .. vim.fs.basename(f))
			end
		end,
		config = function()
			link_legacy_captures()
			vim.api.nvim_create_autocmd("ColorScheme", { callback = link_legacy_captures })
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "jai",
				callback = function(ev)
					-- falls back to jai.vim's regex syntax if the parser isn't built
					pcall(vim.treesitter.start, ev.buf, "jai")
				end,
			})
		end,
	},
}
