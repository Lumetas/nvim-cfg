local on_attach = function(client, bufnr)
	local opts = { noremap = true, silent = true, buffer = bufnr }

	vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts) -- Переход к определению
	vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts) -- Переход к объявлению
	vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts) -- Переход к реализации
	vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts) -- Показать ссылки
	vim.keymap.set('n', 'gk', vim.lsp.buf.hover, opts) -- Показать информацию о символе
	vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
end

local lspconfig = require('lspconfig')
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
		update_in_insert = false,
	}
)



-- lspconfig.phpactor.setup({
	-- 	on_attach = on_attach,
	-- 	capabilities = require('cmp_nvim_lsp').default_capabilities(),
	-- 	init_options = {
		-- 		["language_server.diagnostics_on_save"] = true,
		-- 		["language_server.diagnostics_on_update"] = true
		-- 	},
		-- 	-- Отключаем проблемные параметры
		-- 	settings = {
			-- 		language_server_psalm = nil,
			-- 		language_server_phpstan = nil
			-- 	}
			-- })

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




-- lspconfig.rust_analyzer.setup {
--   on_attach = on_attach,  -- Ваша функция on_attach (если есть)
--   cmd = { "rust-analyzer" },  -- Путь к бинарнику (обычно в PATH после `rustup component add rust-analyzer`)
--   filetypes = { "rust" },
--   root_dir = lspconfig.util.root_pattern("Cargo.toml", ".git"),  -- Ищет Cargo.toml или .git как корень проекта
--   settings = {
	--     ["rust-analyzer"] = {
		--       cargo = {
			--         allFeatures = true,  -- Анализировать все фичи Cargo
			--       },
			--       diagnostics = {
				--         enable = true,  -- Включить диагностику
				--       },
				--     },
				--   },
				-- }

local cmp = require("cmp")
cmp.setup({

	mapping = {
		["<C-Space>"] = cmp.mapping.complete(),
		-- Стандартные хоткеи
		["<C-CR>"] = cmp.mapping.confirm({ select = true }),
		["<C-n>"] = cmp.mapping.select_next_item(),
		["<C-p>"] = cmp.mapping.select_prev_item(),
	},
	sources = {
		{ name = "nvim_lsp", option = {         php = {
			keyword_pattern = [=[[\%(\$\k*\)\|\k\+]]=],
		}}},    -- LSP-дополнения
	},
})
