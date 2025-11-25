return {
	cmd = { "phpactor", "language-server" },
	filetypes = { "php" },
	root_markers = { "composer.json", ".git", "phpstan.neon", "lstart.conf", ".lumproject" },
	settings = {
		phpactor = {
			format = {
				enable = true -- Включить автоформатирование
			},
			diagnostics = {
				enable = true -- Включить диагностику
			}
		}
	}
}			
