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
						library = vim.list_extend(
							vim.api.nvim_get_runtime_file("", true),
							vim.fn.isdirectory("/usr/share/hypr/stubs") == 1 and { "/usr/share/hypr/stubs" } or {}
						),
					},
					diagnostics = { globals = { "vim" } },
					telemetry = { enable = false },
				},
			},
		})

		-- Store-installed pwsh is an app execution alias: executable() is 0 for it, also for its full path, but
		-- starting it by full path works. lspconfig and vim.lsp check executable() for a cmd list, so cmd is a
		-- function that starts the server itself.

		local pses = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services"
		local pwsh_alias = vim.env.LOCALAPPDATA .. "\\Microsoft\\WindowsApps\\pwsh.exe"
		local shell = vim.fn.executable("pwsh") == 1 and "pwsh"
			or (vim.uv.fs_lstat(pwsh_alias) and pwsh_alias)
			or "powershell.exe"
		local cache = vim.fn.stdpath("cache")
		vim.lsp.config("powershell_es", {
			bundle_path = pses,
			shell = shell,
			cmd = function(dispatchers)
				return vim.lsp.rpc.start({
					shell,
					"-NoLogo",
					"-NoProfile",
					"-Command",
					(
						"& '%s/PowerShellEditorServices/Start-EditorServices.ps1' -LogPath '%s/powershell_es.log'"
						.. " -SessionDetailsPath '%s/powershell_es.session.json' -FeatureFlags @() -AdditionalModules @()"
						.. " -HostName nvim -HostProfileId 0 -HostVersion 1.0.0 -Stdio -LogLevel Information"
					):format(pses, cache, cache),
				}, dispatchers)
			end,
			-- rename is gated behind a disclaimer prompt; declining it disables rename for the session
			settings = { powershell = { rename = { acceptDisclaimer = true } } },
		})
	end,
}
