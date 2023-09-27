return function(lnpm)
	lnpm.load('akinsho/git-conflict.nvim', function(plugin)
		plugin.setup({
			default_mappings = {
				ours = '<leader>gc',
				theirs = '<leader>gi',
				none = '<leader>g0',
				both = '<leader>gb',
				next = ']c',
				prev = '[c',
			},
		})


	end, {name = 'git-conflict'})

end
