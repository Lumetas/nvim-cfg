return function(lnpm)
	lnpm.load('phaazon/hop.nvim', function(hop)
		hop.setup()
		vim.api.nvim_set_keymap('n', 's', ':HopWord<CR>', { noremap = true })
		vim.api.nvim_set_keymap('n', 'S', ':HopAnywhere<CR>', { noremap = true })
	end, {name = "hop"})
end
