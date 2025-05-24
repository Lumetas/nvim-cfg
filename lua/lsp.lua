local on_attach = function(client, bufnr)
	local opts = { noremap = true, silent = true, buffer = bufnr }

	vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts) -- Переход к определению
	vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts) -- Переход к объявлению
	vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts) -- Переход к реализации
	vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts) -- Показать ссылки
	vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts) -- Показать информацию о символе

	-- Переход к предыдущему буферу и закрытие текущего (если возможно)
	vim.keymap.set('n', 'gp', function()
		-- Получаем текущий буфер
		local current_buf = vim.api.nvim_get_current_buf()

		-- Проверяем, можно ли удалить текущий буфер
		local is_deletable = vim.fn.buflisted(current_buf) == 1

		-- Получаем предыдущий буфер
		local prev_buf = vim.fn.bufnr('#')

		-- Если предыдущий буфер существует и доступен, переходим к нему
		if prev_buf ~= -1 and vim.fn.buflisted(prev_buf) == 1 then
			vim.cmd('b#') -- Переход к предыдущему буферу

			-- Если текущий буфер можно удалить, закрываем его
			if is_deletable then
				vim.api.nvim_buf_delete(current_buf, { force = true })
			end
		else
			-- Если предыдущего буфера нет, просто выводим сообщение
			vim.notify("Нет предыдущего буфера для перехода", vim.log.levels.WARN)
		end
	end, opts)
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
