return {
	cmd = { "pyright-langserver", "--stdio" },
	filetypes = { "python"},
	root_markers = { "pyproject.toml", "setup.py", "requirements.txt", "Pipfile", "poetry.lock", ".git", "pyvenv.cfg" },
	settings = {
		python = {
			analysis = {
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				diagnosticMode = "workspace",
			},
		},
	}
}
