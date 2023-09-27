return function(lnpm)

	local lrule = function(next)
		vim.keymap.set('n', '<leader>la', function() next() vim.cmd('LumQuickCommandsAdd') end, { desc = 'Add quick command' })
		vim.keymap.set('n', '<leader>ls', function() next() vim.cmd('LumQuickCommandsShow') end, { desc = 'Show quick commands' })
	end

	lnpm.load('lumetas/LQC', function(LQC)
		LQC.setup({
			name_separator = '     ',
		})

		vim.api.nvim_set_keymap('n', '<leader>la', ':LumQuickCommandsAdd<CR>', { noremap = true, desc = 'Add quick command' })
		vim.api.nvim_set_keymap('n', '<leader>ls', ':LumQuickCommandsShow<CR>', { noremap = true, desc = 'Show quick commands' })
	end, {lrule = lrule})

end
