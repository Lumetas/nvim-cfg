vim.o.foldcolumn = '1'
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

-- Инициализация ufo
vim.keymap.set('n', '<leader>zo', require('ufo').openAllFolds)
vim.keymap.set('n', '<leader>zc', require('ufo').closeAllFolds)

require('ufo').setup({
    provider_selector = function(bufnr, filetype, buftype)
        return { 'treesitter', 'indent' }
    end
})
