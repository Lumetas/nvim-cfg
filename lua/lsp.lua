vim.lsp.enable({ "intelephense", "ts_ls", "html" })

-- 3. Настройка диагностики
vim.diagnostic.config({
	virtual_text = false,
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		source = "always",
		border = "rounded",
		focusable = false,
	}
})

-- 4. Автокоманды (LspAttach и LspRestart при смене директории)
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local bufnr = args.buf
		local opts = { noremap = true, silent = true, buffer = bufnr }

		local map = function(mode, lhs, rhs, desc)
			opts.desc = desc
			vim.keymap.set(mode, lhs, rhs, opts)
		end

		map('n', 'gd', vim.lsp.buf.definition, "Go to definition")
		map('n', 'gD', vim.lsp.buf.declaration, "Go to declaration")
		map('n', 'gi', vim.lsp.buf.implementation, "Go to implementation")
		map('n', '<leader>ar', vim.lsp.buf.references, "References")
		map('n', '<leader>ac', vim.lsp.buf.code_action, "Code action")
		map('n', '<leader>af', function() vim.lsp.buf.format { async = true } end, "Format")
		map('n', '<leader>ai', vim.lsp.buf.hover, "Symbol Info")
		map('n', '<leader>al', vim.lsp.buf.rename, "Rename")
	end,
})

