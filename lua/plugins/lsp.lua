return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp",
	},
	config = function()
		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		vim.lsp.config("*", { capabilities = capabilities })
		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					runtime = { version = "LuaJIT" },
					workspace = {
						checkThirdParty = false,
						library = vim.api.nvim_get_runtime_file("", true),
					},
					diagnostics = { globals = { "vim" } },
					telemetry = { enable = false },
				},
			},
		})
		vim.lsp.config("powershell_es", {
			bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services",
			shell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell.exe",
			-- rename is gated behind a disclaimer prompt; declining it disables rename for the session
			settings = { powershell = { rename = { acceptDisclaimer = true } } },
		})
	end,
}
