require('orgmode').setup({
	org_agenda_files = org_path .. '/**/*',
	org_default_notes_file = org_path .. '/refile.org',
	org_babel = {
		-- Поддержка языков (нужны соответствующие `treesitter` парсеры)
		supported_languages = {
			"python",
			"bash",
			"php"
		},
		python = {
			cmd = "python3",  -- или путь к venv: "~/venv/bin/python"
		},
	},
	org_todo_keywords = {'TODO', 'PROGRESS', '|', 'DONE', 'DELEGATED'},
	org_hide_leading_stars = true,
	org_startup_indented = true,
	org_babel_default_header_args = { [':tangle'] = 'yes', [':noweb'] = 'yes' }
})
