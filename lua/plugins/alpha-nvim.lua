return {
	"goolord/alpha-nvim",
	event = "VimEnter",
	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")

		package.path = package.path .. ";" .. vim.fn.stdpath("config") .. "/?.lua"
		local arts = require("ascii_arts")

		math.randomseed(os.time())
		local cat = arts[math.random(#arts)]

		local padding = math.floor((vim.fn.winheight(0) - #cat) / 2) - 4
		for _ = 1, padding do
			table.insert(cat, 1, "")
		end

		dashboard.section.header.val = cat
		dashboard.section.buttons.val = {}
		dashboard.section.footer.val = {}

		alpha.setup(dashboard.config)
	end,
}
