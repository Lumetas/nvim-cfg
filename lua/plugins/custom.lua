return function(lnpm)
	lnpm.load('nvim-lua/plenary.nvim')
	lnpm.load('nvim-tree/nvim-web-devicons', nil, {lrule = function(next) vim.defer_fn(next, 1000) end})
	lnpm.load('kevinhwang91/promise-async')

	lnpm.load('kylechui/nvim-surround', function(surround) surround.setup() end, {lrule = function (next) vim.defer_fn(next, 1000) end})

	lnpm.load('nvim-treesitter/nvim-treesitter', function(ts)
		ts.setup({
			ensure_installed = {
				'php', 'javascript', 'css', 'html', 'markdown', 
				'lua', 'go', 'python', 'blade'
			},
			-- Опционально: автоматическая установка недостающих парсеров
			auto_install = true,

			-- Остальные настройки (пример):
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
			},
			indent = {
				enable = true,
			},
		})
	end, {
	lrule = function(next) 
		vim.defer_fn(next, 100) 
	end
})

lnpm.load('mattn/emmet-vim', nil, {lrule = function(next) vim.defer_fn(next, 1000) end})


lnpm.load('kevinhwang91/nvim-bqf', nil, {lrule = function(next) vim.defer_fn(next, 1000) end})


lnpm.load('mikavilpas/yazi.nvim', function() 
	vim.api.nvim_set_keymap('n', 'zx', ':Yazi<CR>', { noremap = true })
end, {lrule = function (next) 
vim.keymap.set('n', 'zx', function() 
	next()
	vim.cmd('Yazi')
end, { noremap = true })
	end})
end
