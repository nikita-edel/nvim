local vim = vim

local conform_state_file = table.concat({
	vim.fn.stdpath("state"),
	"conform_enabled",
}, package.config:sub(1, 1))

local function read_conform_enabled()
	if vim.fn.filereadable(conform_state_file) ~= 1 then
		return true
	end
	local lines = vim.fn.readfile(conform_state_file)
	local state = lines[1]
	if state ~= nil then
		state = vim.trim(state)
	end
	return state == "on"
end

local function write_conform_enabled(value)
	vim.fn.mkdir(vim.fn.stdpath("state"), "p")
	if value then
		vim.fn.writefile({ "on" }, conform_state_file)
	else
		vim.fn.writefile({ "off" }, conform_state_file)
	end
end

local conform_enabled = read_conform_enabled()

local function toggle_conform()
	conform_enabled = not conform_enabled
	write_conform_enabled(conform_enabled)
	vim.notify("conform.nvim formatting: " .. (conform_enabled and "ON" or "OFF"))
end

local function notify_conform()
	vim.notify("conform.nvim formatting: " .. (conform_enabled and "ON" or "OFF"))
end

return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	init = function()
		vim.api.nvim_create_user_command("Fmt", toggle_conform, { force = true })
		vim.api.nvim_create_user_command("FmtI", notify_conform, { force = true })
	end,
	opts = {
		formatters_by_ft = {
			c = { "clang_format" },
			cpp = { "clang_format" },
			lua = { "stylua" },
		},
		formatters = {
			clang_format = {
				condition = function(ctx)
					return vim.fs.find(".clang-format", { upward = true, path = ctx.dirname })[1] ~= nil
				end,
			},
		},
		format_on_save = function(bufnr)
			if conform_enabled == false then
				return false
			end
			return { timeout_ms = 1000, lsp_fallback = false }
		end,
	},
	config = function(_, opts)
		require("conform").setup(opts)
	end,
}
