return function(lnpm)
	lnpm.load('phaazon/hop.nvim', function(hop)
		hop.setup()
		vim.api.nvim_set_keymap('n', 's', ':HopWord<CR>', { noremap = true, desc = "Hop Word" })
		vim.api.nvim_set_keymap('n', 'S', ':HopAnywhere<CR>', { noremap = true, desc = "Hop Anywhere" })
		vim.keymap.set('v', 's', function () vim.cmd('HopWord') end, { noremap = true , desc = "Hop Word" })
		vim.keymap.set('v', 'S', function () vim.cmd('HopAnywhere') end, { noremap = true, desc = "Hop Anywhere" })
	end, {name = "hop"})
end
