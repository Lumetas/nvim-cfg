return function(lnpm)

	lnpm.load('lumetas/LQC', function(LQC)
		LQC.setup({
			name_separator = '     ',
		})

		vim.api.nvim_set_keymap('n', '<leader>la', ':LumQuickCommandsAdd<CR>', { noremap = true, desc = 'Add quick command' })
		vim.api.nvim_set_keymap('n', '<leader>ls', ':LumQuickCommandsShow<CR>', { noremap = true, desc = 'Show quick commands' })
	end)

end
