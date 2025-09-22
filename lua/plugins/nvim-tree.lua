return function(lnpm)
	lnpm.load('nvim-tree/nvim-tree.lua', function(tree)
		tree.setup({
			git = {
				enable = true,
				timeout = 400,
			},
			filesystem_watchers = {
				enable = false,  -- ускоряет работу, но требует ручного обновления (клавиша `R`)
			},
			renderer = {
				group_empty = true,  -- схлопывать пустые папки
				indent_markers = {
					enable = true,
				},
			},
			actions = {
				change_dir = {
					global = false,  -- не менять корневую папку без указания
				},
				open_file = {
					quit_on_open = false,
				},
			},
		})


		vim.api.nvim_set_keymap('n', '<C-n>', ':NvimTreeToggle<CR>', { noremap = true })
		vim.api.nvim_set_keymap('n', '<C-b>', ':NvimTreeFocus<CR>', { noremap = true })


		vim.api.nvim_create_augroup('NERDTreeAutoUpdate', { clear = true })
		vim.api.nvim_create_autocmd('DirChanged', {
			group = 'NERDTreeAutoUpdate',
			pattern = '*',
			callback = function()
				require("nvim-tree.api").tree.change_root(vim.fn.getcwd())
			end,
		})

	end, {
	name = "nvim-tree",
	git = false,
	install_path = '~'
})
end
