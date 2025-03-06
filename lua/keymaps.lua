-- Insert mode mappings
vim.api.nvim_set_keymap('i', '<C-BS>', '<C-w>', { noremap = true })

-- NERDTree mappings
vim.api.nvim_set_keymap('n', '<C-n>', ':NERDTreeToggle<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-b>', ':NERDTreeFocus<CR>:NERDTreeRefreshRoot<CR>', { noremap = true })

-- General mappings
vim.api.nvim_set_keymap('i', '<A-f>', '<ESC>', { noremap = true })
vim.api.nvim_set_keymap('n', '<TAB>', 'gt', { noremap = true })

-- Visual mode mappings
vim.api.nvim_set_keymap('v', '<A-C-l>', '$', { noremap = true })
vim.api.nvim_set_keymap('v', '<A-C-H>', '0', { noremap = true })
vim.api.nvim_set_keymap('v', '<C-h>', 'b', { noremap = true })
vim.api.nvim_set_keymap('v', '<C-l>', 'w', { noremap = true })

-- Normal mode mappings
vim.api.nvim_set_keymap('n', '<A-C-l>', '$', { noremap = true })
vim.api.nvim_set_keymap('n', '<A-C-H>', '0', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-h>', 'b', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-l>', 'w', { noremap = true })
vim.api.nvim_set_keymap('n', '<ESC>', ':nohl<CR>', { noremap = true })
vim.api.nvim_set_keymap('t', '<A-f>', '<C-\\><C-n>', { noremap = true })
vim.api.nvim_set_keymap('n', 'q:', '<Nop>', { noremap = true })
vim.api.nvim_set_keymap('n', 'J', '<C-d>', { noremap = true })
vim.api.nvim_set_keymap('n', 'K', '<C-u>', { noremap = true })

-- Delete without yanking
vim.api.nvim_set_keymap('v', 'd', '"_d', { noremap = true })
vim.api.nvim_set_keymap('n', 'd', '"_d', { noremap = true })
