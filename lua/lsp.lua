local on_attach = function(client, bufnr)
	local opts = { noremap = true, silent = true, buffer = bufnr }

	vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts) -- Переход к определению
	vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts) -- Переход к объявлению
	vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts) -- Переход к реализации
	vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts) -- Показать ссылки
	vim.keymap.set('n', 'gk', vim.lsp.buf.hover, opts) -- Показать информацию о символе
end

local lspconfig = require('lspconfig')

-- lspconfig.phpactor.setup {
-- 	on_attach = on_attach,
-- 	filetypes = { "php" },
-- 	root_dir = function(fname)
-- 		return lspconfig.util.root_pattern("composer.json", ".git")(fname) or vim.fn.getcwd()
-- 	end,
-- 	init_options = {
-- 		["language_server_phpstan.enabled"] = false,
-- 		["language_server_psalm.enabled"] = false,
-- 	}
-- }

lspconfig.intelephense.setup {
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

lspconfig.rust_analyzer.setup {
  on_attach = on_attach,  -- Ваша функция on_attach (если есть)
  cmd = { "rust-analyzer" },  -- Путь к бинарнику (обычно в PATH после `rustup component add rust-analyzer`)
  filetypes = { "rust" },
  root_dir = lspconfig.util.root_pattern("Cargo.toml", ".git"),  -- Ищет Cargo.toml или .git как корень проекта
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,  -- Анализировать все фичи Cargo
      },
      diagnostics = {
        enable = true,  -- Включить диагностику
      },
    },
  },
}
