-- Включаем русскую раскладку
vim.opt.keymap = 'russian-jcukenwin'

-- По умолчанию раскладка выключена (английская)
vim.opt.iminsert = 0
vim.opt.imsearch = 0

-- Переключение раскладки в Insert mode с помощью <C-l>
vim.api.nvim_set_keymap('i', '<C-l>', '<C-^>', { noremap = true, silent = true })

-- Автоматически возвращаем раскладку к английской при выходе из Insert mode (если флаг true)
vim.cmd([[
  augroup AutoEnglishLayout
    autocmd!
    autocmd InsertLeave * lua if vim.g.reset_layout_on_leave then vim.opt.iminsert = 0 end
  augroup END
]])
