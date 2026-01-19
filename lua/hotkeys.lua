-- Insert mode mappings
vim.api.nvim_set_keymap('i', '<C-BS>', '<C-w>', { noremap = true })

vim.keymap.set('n', '\\', ':echo "Use Space now!"<CR>', { noremap = true })

-- NERDTree mappings
-- vim.api.nvim_set_keymap('n', '<C-n>', ':NERDTreeToggle<CR>', { noremap = true })
-- vim.api.nvim_set_keymap('n', '<C-b>', ':NERDTreeFocus<CR>:NERDTreeRefreshRoot<CR>', { noremap = true })

vim.api.nvim_set_keymap('n', '<A-l>', '<C-w>l', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<A-h>', '<C-w>h', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<A-k>', '<C-w>k', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<A-j>', '<C-w>j', {noremap = true, silent = true})

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
vim.api.nvim_set_keymap('n', '<ESC>', ':nohl<CR>', { noremap = true })
vim.api.nvim_set_keymap('t', '<A-f>', '<C-\\><C-n>', { noremap = true })
vim.api.nvim_set_keymap('t', '<C-o>', '<C-\\><C-o>', { noremap = true })
vim.api.nvim_set_keymap('n', 'q:', '<Nop>', { noremap = true })

-- Delete without yanking
vim.api.nvim_set_keymap('v', 'd', '"_d', { noremap = true })
vim.api.nvim_set_keymap('n', 'd', '"_d', { noremap = true })
vim.api.nvim_set_keymap('n', 'x', 'd', { noremap = true })


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

local LAST_REGISTER = nil
-- Для Yank (копирования)
vim.keymap.set({'n', 'v'}, '<leader>y', function()
    local reg = vim.fn.getchar()
    if type(reg) == 'number' then
        reg = string.char(reg)
    end
	LAST_REGISTER = reg
    
	print("Yank to " .. reg)
    if vim.fn.mode() == 'n' then
        -- Нормальный режим: "ayy
        return '"' .. reg .. 'yy'
    else
        -- Визуальный режим: "ay
        return '"' .. reg .. 'y'
    end
end, {expr = true, desc = "Yank to specific register"})

vim.keymap.set({'n', 'v'}, '<leader>y<leader>', function()
	if LAST_REGISTER then
		if vim.fn.mode() == 'n' then
			print ("Yank to " .. string.upper(LAST_REGISTER))
			return '"' .. string.upper(LAST_REGISTER) .. 'yy'
		else 
			print ("Yank to " .. string.upper(LAST_REGISTER))
			return '"' .. string.upper(LAST_REGISTER) .. 'y'
		end
	else 
		print ("Last register is not set")
	end
end, {expr = true, desc = "Yank to last register"})

-- Для Paste (вставки) - только в нормальном режиме
vim.keymap.set('n', '<leader>p', function()
    local reg = vim.fn.getchar()
    if type(reg) == 'number' then
        reg = string.char(reg)
    end
	print("Paste from " .. reg)
    -- Нормальный режим: "ap
    return '"' .. reg .. 'p'

end, {expr = true, desc = "Paste from specific register"})


vim.api.nvim_set_keymap('v', '>', '>gv', { noremap = true, desc = 'Move to next match' })
vim.api.nvim_set_keymap('v', '<', '<gv', { noremap = true, desc = 'Move to previous match' })



vim.api.nvim_set_keymap('n', '<Leader>w', ':up<CR>', { noremap = true, desc = 'Write'})
vim.api.nvim_set_keymap('n', '<Leader>q', ':q<CR>', { noremap = true, desc = 'Quit'})
vim.api.nvim_set_keymap('n', '<Leader><leader>q', ':q!<CR>', { noremap = true, desc = 'Quit!'})



vim.api.nvim_set_keymap('n', '<leader>m', '', { noremap = true, desc = 'Move' }) 
vim.api.nvim_set_keymap('n', '<leader>mj', ':HopLine<CR>', { noremap = true, desc = 'Move to line' })
vim.api.nvim_set_keymap('n', '<leader>mn', ':cnext<CR>', { noremap = true, desc = 'Move to next match' })
vim.api.nvim_set_keymap('n', '<leader>mp', ':cprev<CR>', { noremap = true, desc = 'Move to previous match' })

vim.api.nvim_set_keymap('n', '<C-k>', '5k', { noremap = true, desc = 'Move up 5 lines' })
vim.api.nvim_set_keymap('n', '<C-j>', '5j', { noremap = true, desc = 'Move down 5 lines' })

vim.api.nvim_set_keymap('n', '<leader>mv', ':normal `1v`2<CR>',  { noremap = true, desc = 'Select from 1 to 2 marks' })
