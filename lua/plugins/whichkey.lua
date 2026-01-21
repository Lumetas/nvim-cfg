return function(lnpm)
    lnpm.load('folke/which-key.nvim', nil , { name = 'which-key', lrule = function(next) vim.defer_fn(next, 1000) end })
end
