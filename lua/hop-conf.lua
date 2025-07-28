require'hop'.setup()
vim.api.nvim_set_keymap('n', 's', ':HopWord<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', 'S', ':HopAnywhere<CR>', { noremap = true })
