return function(lnpm)

	lnpm.load("tpope/vim-dadbod", function(nl) 
		lnpm.load("kristijanhusak/vim-dadbod-completion", nil , {name = "vim-dadbod-completion"})
		lnpm.load("kristijanhusak/vim-dadbod-ui", nil , {name = "vim-dadbod-ui"})
	end, {name = "vim-dadbod", lrule = function(next) vim.defer_fn(next, 1000) end})
end
