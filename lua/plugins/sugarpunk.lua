local testing = false

local config = {
	priority = 1000,
	config = function()
		vim.cmd.colorscheme("sugarpunk")
	end,
}

if testing then
	config.dir = "~/dev/sugarpunk.nvim"
else
	config[1] = "nikita-edel/sugarpunk.nvim"
end

return config
