-- Insert mode mappings
vim.api.nvim_set_keymap('i', '<C-BS>', '<C-w>', { noremap = true })

vim.keymap.set('n', '\\', ':echo "Use Space now!"<CR>', { noremap = true })

-- NERDTree mappings
-- vim.api.nvim_set_keymap('n', '<C-n>', ':NERDTreeToggle<CR>', { noremap = true })
-- vim.api.nvim_set_keymap('n', '<C-b>', ':NERDTreeFocus<CR>:NERDTreeRefreshRoot<CR>', { noremap = true })

-- Alt+l для перехода в правое окно (аналог Ctrl+w l)
vim.api.nvim_set_keymap('n', '<A-l>', '<C-w>l', {noremap = true, silent = true})

-- Alt+h для перехода в левое окно (аналог Ctrl+w h)
vim.api.nvim_set_keymap('n', '<A-h>', '<C-w>h', {noremap = true, silent = true})

-- Аналогично для других направлений
vim.api.nvim_set_keymap('n', '<A-k>', '<C-w>k', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<A-j>', '<C-w>j', {noremap = true, silent = true})

vim.api.nvim_set_keymap('n', '<C-n>', ':NvimTreeToggle<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-b>', ':NvimTreeFocus<CR>', { noremap = true })

vim.api.nvim_set_keymap('n', 'zz', ':FZF<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>rr', ':%s/\\v', { noremap = true, desc = 'Replace' })
vim.api.nvim_set_keymap('v', '<leader>rr', ':s/\\v', { noremap = true, desc = 'Replace' })

-- General mappings
vim.api.nvim_set_keymap('i', '<A-f>', '<ESC>', { noremap = true })
vim.api.nvim_set_keymap('v', '<A-f>', '<ESC>', { noremap = true })
vim.api.nvim_set_keymap('n', '<A-f>', ':nohl<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<TAB>', 'gt', { noremap = true })

vim.api.nvim_set_keymap('n', '<CR>', 'za', { noremap = true })
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
vim.api.nvim_set_keymap('t', '<C-o>', '<C-\\><C-o>', { noremap = true })
vim.api.nvim_set_keymap('n', 'q:', '<Nop>', { noremap = true })
vim.api.nvim_set_keymap('n', 'J', '<C-d>', { noremap = true })
vim.api.nvim_set_keymap('n', 'K', '<C-u>', { noremap = true })

vim.api.nvim_set_keymap('v', 'J', '<C-d>', { noremap = true })
vim.api.nvim_set_keymap('v', 'K', '<C-u>', { noremap = true })

-- Delete without yanking
vim.api.nvim_set_keymap('v', 'd', '"_d', { noremap = true })
vim.api.nvim_set_keymap('n', 'd', '"_d', { noremap = true })


-- vim.api.nvim_set_keymap('n', '<C-p>h', ':LumSNhtml<CR>', { noremap = true })
-- vim.api.nvim_set_keymap('n', '<C-p>c', ':LumSNcss<CR>', { noremap = true })
-- vim.api.nvim_set_keymap('n', '<C-p>j', ':LumSNjs<CR>', { noremap = true })

vim.keymap.set('n', 'gp', function()
	vim.cmd('b#')
end, { noremap = true, desc = 'Go to previous buffer' })


vim.api.nvim_set_keymap('n', '<leader>st', ':diffthis<CR>', { noremap = true, desc = 'Open Diff' })
vim.api.nvim_set_keymap('n', '<leader>sp', ':diffput<CR>', { noremap = true, desc = 'Diff Put' })
vim.api.nvim_set_keymap('n', '<leader>sg', ':diffget<CR>', { noremap = true, desc = 'Diff Get' })
vim.api.nvim_set_keymap('n', '<leader>so', ':diffoff<CR>', { noremap = true, desc = 'Disable Diff' })
vim.api.nvim_set_keymap('n', '<leader>sd', ':diffoff!<CR>', { noremap = true, desc = 'Disable Diff!' })


vim.api.nvim_set_keymap('v', '<leader>el', ':lua<CR>', { noremap = true, desc = 'Execute Lua' })


vim.api.nvim_set_keymap('n', '<Leader>w', ':w<CR>', { noremap = true, desc = 'Write'})
vim.api.nvim_set_keymap('n', '<Leader>q', ':q<CR>', { noremap = true, desc = 'Quit'})



vim.api.nvim_set_keymap('n', '<leader>m', '', { noremap = true, desc = 'Move' }) 
vim.api.nvim_set_keymap('n', '<leader>mj', ':HopLine<CR>', { noremap = true, desc = 'Move to line' })

