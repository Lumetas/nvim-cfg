return function(lnpm)
	lnpm.load('neovim/nvim-lspconfig', function()
		vim.diagnostic.config({
			virtual_text = {
				source = "always",  -- Показывать источник диагностики
				prefix = '■',       -- Префикс для виртуального текста
				spacing = 4,
			},
			signs = true,
			underline = true,
			update_in_insert = false,
			severity_sort = true,
			float = {
				source = "always",  -- Показывать источник в float окне
			}
		})



		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(args)
				local bufnr = args.buf
				local client = vim.lsp.get_client_by_id(args.data.client_id)

				-- Example: Set up keybindings for common LSP actions
				vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { noremap = true, desc = "Go to definition", silent = true, buffer = bufnr })
				vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { noremap = true, desc = "Go to declaration", silent = true, buffer = bufnr })
				vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { noremap = true, desc = "Go to implementation", silent = true, buffer = bufnr })
				vim.keymap.set('n', '<leader>ar', vim.lsp.buf.references, { noremap = true, desc = "References", silent = true, buffer = bufnr })
				vim.keymap.set('n', '<leader>ac', vim.lsp.buf.code_action, { noremap = true, desc = "Code action", silent = true, buffer = bufnr })
				vim.keymap.set('n', '<leader>af', vim.lsp.buf.format, { noremap = true, desc = "Format", silent = true, buffer = bufnr })
				vim.keymap.set('n', '<leader>ai', vim.lsp.buf.hover, { noremap = true, desc = "Symbol Info", silent = true, buffer = bufnr })
				vim.keymap.set('n', '<leader>al', vim.lsp.buf.rename, { noremap = true, desc = "Rename", silent = true, buffer = bufnr })
			end,
		})

		vim.lsp.config('*', {
			root_markers = { '.git' },
		})


	end)
end
