return {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
	root_markers = { "tsconfig.json", "jsconfig.json", ".git", "package.json", "js", "ts", "index.html"},
	settings = {
		typescript = {
		}
	}
}
