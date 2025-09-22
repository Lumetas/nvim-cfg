return function(lnpm)
	lnpm.load('tpope/vim-fugitive', function()
		vim.api.nvim_set_keymap('n', '<Leader>ga', ':G add .<CR>', { noremap = true, desc = 'Git add'})
		vim.api.nvim_set_keymap('n', '<Leader>gc', ':G commit<CR>', { noremap = true, desc = 'Git commit'})
		vim.api.nvim_set_keymap('n', '<Leader>gp', ':G pull<CR>', { noremap = true, desc = 'Git pull'})
		vim.api.nvim_set_keymap('n', '<Leader>gP', ':G push<CR>', { noremap = true, desc = 'Git push'})
		vim.api.nvim_set_keymap('n', '<Leader>gl', ':Gllog<CR>', { noremap = true, desc = 'Git log'})
		vim.api.nvim_set_keymap('n', '<Leader>gs', ':G status<CR>', { noremap = true, desc = 'Git status'})
		vim.api.nvim_set_keymap('n', '<Leader>gac', ':G add . | G commit<CR>', { noremap = true, desc = 'and commit'})
		vim.api.nvim_set_keymap('n', '<Leader>gg', ':G ', { noremap = true, desc = 'Git custom'})


		vim.api.nvim_set_keymap('n', '<Leader>gC', '', { noremap = true, desc = 'Git config'})



		vim.api.nvim_set_keymap('n', '<Leader>gCem', ':G config user.email lumetas506@gmail.com | echo "set main email"<CR>', { noremap = true, desc = 'Set main email'})
		vim.api.nvim_set_keymap('n', '<Leader>gCew', ':G config user.email p.teplyakov@emfy.com | echo "set work email"<CR>', { noremap = true, desc = 'Set work email'})
		vim.api.nvim_set_keymap('n', '<Leader>gCe', ':G config user.email<CR>', { noremap = true, desc = 'Email'})




		vim.api.nvim_set_keymap('n', '<Leader>gCnm', ':G config user.name Lumetas | echo "set main name"<CR>', { noremap = true, desc = 'Set main name'})
		vim.api.nvim_set_keymap('n', '<Leader>gCnw', ':G config user.name Pavel | echo "set work name"<CR>', { noremap = true, desc = 'Set work name'})
		vim.api.nvim_set_keymap('n', '<Leader>gCn', ':G config user.name<CR>', { noremap = true, desc = 'Name'})
	end)
end
