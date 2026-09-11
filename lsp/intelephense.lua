local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true
return {
	cmd = { "intelephense", "--stdio" },
	filetypes = { "php" },
	root_markers = { "composer.json", ".git", "phpstan.neon", "lstart.conf", ".lumproject" },
	capabilities = capabilities,
	settings = {
		intelephense = {
			format = {
				enable = true -- Включить автоформатирование
			},
			diagnostics = {
				enable = true -- Включить диагностику
			}
		}
	}
}
