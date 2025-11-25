return function(lnpm)
	lnpm.load('neovim/nvim-lspconfig', function()

		vim.lsp.enable({"intelephense", "ts_ls"})
		vim.diagnostic.config({
			virtual_text = false,  -- Отключаем виртуальный текст в коде
			signs = true,          -- Включаем значки на номерах строк
			underline = true,      -- Подчеркивание проблемных мест
			update_in_insert = false,
			severity_sort = true,
			float = {
				source = "always",  -- Показывать источник в float окне
				border = "rounded",
				focusable = false,
			}
		})

		-- Функция для показа диагностики в float окне
		local function show_diagnostics()
			local opts = {
				focusable = false,
				close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
				border = 'rounded',
				source = 'always',
				prefix = ' ',
				scope = 'cursor',
			}
			vim.diagnostic.open_float(nil, opts)
		end

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
				
				-- Показ диагностики по нажатию <leader>k
				vim.keymap.set('n', '<leader>k', show_diagnostics, { noremap = true, desc = "Show diagnostics", silent = true, buffer = bufnr })
			end,
		})

		vim.lsp.config('*', {
			root_markers = { '.git' },
		})

		vim.api.nvim_create_augroup('LSPAutoRestart', { clear = true })
		vim.api.nvim_create_autocmd('DirChanged', {
			group = 'LSPAutoRestart',
			pattern = '*',
			callback = function()
				vim.cmd('LspRestart')
			end,
		})

	end)
end
