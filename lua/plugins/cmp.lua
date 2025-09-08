return function(lnpm)
lnpm.load('hrsh7th/cmp-nvim-lsp', function()
	local cmp = require("cmp")
	cmp.setup({
		sources = {
			{ name = 'nvim_lsp' }
		}
	})
end)
	lnpm.load('hrsh7th/nvim-cmp', function()
		local cmp = require("cmp")
		cmp.setup({
			completion = {
				-- autocomplete = false, -- Отключаем автоматическое открытие
			},
			mapping = {
				["<C-Space>"] = cmp.mapping.complete(),
				-- Стандартные хоткеи
				["<C-CR>"] = cmp.mapping.confirm({ select = true }),
				["<C-n>"] = cmp.mapping.select_next_item(),
				["<C-p>"] = cmp.mapping.select_prev_item(),
			},
			sources = {
				{ name = 'orgmode' },
				{ 
					name = "nvim_lsp",
					option = {
						php = {
							keyword_pattern = [=[[\%(\$\k*\)\|\k\+]]=],
						}
					}

				},
				{
					name = "buffer",
					option = {

					}

				},
			},
		})
	end, {
	git = false
})
end
