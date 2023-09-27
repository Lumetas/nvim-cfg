return {
	cmd = { "vue-language-server", "--stdio" },
	filetypes = { "vue" },
	root_markers = { "tsconfig.json", "jsconfig.json", ".git", "package.json", "js", "ts", "index.html"},
	settings = {
		vetur = {
			useWorkspaceDependencies = true,
			validation = {
				script = true,
				style = true,
				template = true,
			},
		},
		css = {
			validate = true,
		},
		emmet = {
			includeLanguages = {
				"javascript",
				"javascriptreact",
				"vue",
				"typescript",
				"typescriptreact",
			},
		},
    	typescript = {
      		serverPath = "/home/lum/.local/bin/typescript-language-server",
      		autoSetDiagnostics = true,
      		autoSetHints = true,
      		autoSetRenames = true,
      		autoSetSchemaRequest = true,
      		autoSetSemanticTokens = true,
      		diagnosticsDelay = 1500,
      		disableAutomaticWorkspaceTrust = true,
      		disableDefaultFormatter = true,
      		disableJavascript = true,
      		disableTypeChecking = true,
      		format = {
        		enable = true,
        		options = {
          			tabSize = 2,
          			insertSpaces = true,
          			wrapLineLength = 120,
        		},
      		},
			suggest = {
				autoImports = true,
				autoImportsOnly = true,
				names = true,
				paths = true,
				fromImports = true,
			},
			validate = true,
    	},
		html = {
			validate = true,
		}
	}
}
