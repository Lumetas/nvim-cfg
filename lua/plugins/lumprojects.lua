return function(lnpm)
	lnpm.load('lumetas/lum-projects.nvim', function(lumProjects)
		lumProjects.setup()
		vim.api.nvim_set_keymap('n', '<leader>lp', ':LumProjectsShow<CR>', { noremap = true, desc = 'Show projects' })
		vim.api.nvim_set_keymap('n', '<leader>lt', ':LumProjectsTelescope<CR>', { noremap = true, desc = 'Show projects with telescope' })
		vim.api.nvim_set_keymap('n', '<leader>lr', ':LumProjectsRun<CR>', { noremap = true, desc = 'Run project' })
		vim.api.nvim_set_keymap('n', '<leader>lb', ':LumProjectsBuild<CR>', { noremap = true, desc = 'Build project' })
	end, {name = 'lum-projects'})
end
