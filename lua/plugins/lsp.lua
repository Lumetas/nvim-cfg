return function(lnpm)
	lnpm.load('neovim/nvim-lspconfig', function()
		lspconfig = require('lspconfig')
		local on_attach = function(client, bufnr)
			local opts = { noremap = true, silent = true, buffer = bufnr }

			vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { noremap = true, desc = "Go to definition", silent = true, buffer = bufnr })
			vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { noremap = true, desc = "Go to declaration", silent = true, buffer = bufnr })
			vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { noremap = true, desc = "Go to implementation", silent = true, buffer = bufnr })
			vim.keymap.set('n', '<leader>ar', vim.lsp.buf.references, { noremap = true, desc = "References", silent = true, buffer = bufnr })
			vim.keymap.set('n', '<leader>ac', vim.lsp.buf.code_action, { noremap = true, desc = "Code action", silent = true, buffer = bufnr })
			vim.keymap.set('n', '<leader>af', vim.lsp.buf.format, { noremap = true, desc = "Format", silent = true, buffer = bufnr })
			vim.keymap.set('n', '<leader>ai', vim.lsp.buf.hover, { noremap = true, desc = "Symbol Info", silent = true, buffer = bufnr })
			vim.keymap.set('n', '<leader>al', vim.lsp.buf.rename, { noremap = true, desc = "Rename", silent = true, buffer = bufnr })
		end

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

		-- Кастомизация float окна с диагностикой
		vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
			vim.lsp.diagnostic.on_publish_diagnostics, {
				virtual_text = true,
				signs = true,
				update_in_insert = true,
			}
		)



		lspconfig.intelephense.setup {
			capabilities = require('cmp_nvim_lsp').default_capabilities(),
			on_attach = on_attach,
			cmd = { "intelephense", "--stdio" }, -- Путь к инсталляции Intelephense
			filetypes = { "php" },
			root_dir = function(fname)
				return lspconfig.util.root_pattern("composer.json", ".git")(fname) or vim.fn.getcwd()
			end,
			settings = {
				intelephense = {
					format = {
						enable = true -- Включить автоформатирование
					},
					diagnostics = {
						enable = true -- Включить диагностику
					}
				}
			}
		}

		-- lspconfig.phpactor.setup {
		-- 	capabilities = require('cmp_nvim_lsp').default_capabilities(),
		-- 	on_attach = on_attach,
		-- 	cmd = { "phpactor", "language-server" },
		-- 	filetypes = { "php" },
		-- 	-- Всегда используем текущую рабочую директорию как root
		-- 	root_dir = function(fname)
		-- 		return vim.fn.getcwd()
		-- 	end,
		-- 	init_options = {
		-- 		-- Дополнительные опции инициализации если нужны
		-- 	}
		-- }


		lspconfig.ts_ls.setup {
			capabilities = require('cmp_nvim_lsp').default_capabilities(),
			on_attach = on_attach,
			cmd = { "typescript-language-server", "--stdio" },
			filetypes = {"javascript", "typescript"},
			root_dir = function(fname)
				return lspconfig.util.root_pattern("composer.json", ".git")(fname) or vim.fn.getcwd()
			end,
		}
	end)
end
