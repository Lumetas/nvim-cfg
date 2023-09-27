return {
	cmd = { "vscode-html-language-server", "--stdio" },

	filetypes = { "html", "handlebars", "htmldjango", "css", "scss" },

	-- Маркеры корня проекта
	root_markers = { "package.json", ".git" },

	-- Специфичные настройки сервера
	settings = {
		html = {
			format = {
				enable = true,
				wrapLineLength = 120,
			},
			suggest = {
				html5 = true,
			},
		},
	},

	-- Включение поддержки сниппетов (важно для HTML)
	capabilities = {
		textDocument = {
			completion = {
				completionItem = {
					snippetSupport = true,
				},
			},
		},
	},
}
