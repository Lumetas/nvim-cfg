return {
	cmd = { "intelephense", "--stdio" },
	filetypes = { "php" },
	root_markers = { "composer.json", ".git", "phpstan.neon", "lstart.conf", ".lumproject" },
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
