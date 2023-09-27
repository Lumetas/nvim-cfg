return function(lnpm)
	lnpm.load('romus204/tree-sitter-manager.nvim', function(tree)

		tree.setup({
			ensure_installed = { "bash", "lua", "python", "html", "php", "css", "javascript" }, -- list of parsers to install automatically
			-- Optional: custom paths
			-- parser_dir = vim.fn.stdpath("data") .. "/site/parser",
			-- query_dir = vim.fn.stdpath("data") .. "/site/queries",
		})


	end, {name = 'tree-sitter-manager', lrule = function(next) vim.defer_fn(next, 100) end})

end
