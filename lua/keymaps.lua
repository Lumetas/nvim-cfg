-- Insert mode mappings
vim.api.nvim_set_keymap('i', '<C-BS>', '<C-w>', { noremap = true })

-- NERDTree mappings
-- vim.api.nvim_set_keymap('n', '<C-n>', ':NERDTreeToggle<CR>', { noremap = true })
-- vim.api.nvim_set_keymap('n', '<C-b>', ':NERDTreeFocus<CR>:NERDTreeRefreshRoot<CR>', { noremap = true })

vim.api.nvim_set_keymap('n', '<C-n>', ':NvimTreeToggle<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-b>', ':NvimTreeFocus<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-m>', ':NvimTreeRefresh<CR>', { noremap = true })

-- General mappings
vim.api.nvim_set_keymap('i', '<A-f>', '<ESC>', { noremap = true })
vim.api.nvim_set_keymap('v', '<A-f>', '<ESC>', { noremap = true })
vim.api.nvim_set_keymap('n', '<A-f>', ':nohl<CR>', { noremap = true })
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
vim.api.nvim_set_keymap('t', '<C-o>', '<C-\\><C-o>', { noremap = true })
vim.api.nvim_set_keymap('n', 'q:', '<Nop>', { noremap = true })
vim.api.nvim_set_keymap('n', 'J', '<C-d>', { noremap = true })
vim.api.nvim_set_keymap('n', 'K', '<C-u>', { noremap = true })

-- Delete without yanking
vim.api.nvim_set_keymap('v', 'd', '"_d', { noremap = true })
vim.api.nvim_set_keymap('n', 'd', '"_d', { noremap = true })


vim.api.nvim_set_keymap('n', '<C-p>h', ':LumSNhtml<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-p>c', ':LumSNcss<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-p>j', ':LumSNjs<CR>', { noremap = true })

vim.keymap.set('n', 'gp', function()
	-- Получаем текущий буфер
	local current_buf = vim.api.nvim_get_current_buf()

	-- Проверяем, можно ли удалить текущий буфер
	local is_deletable = vim.fn.buflisted(current_buf) == 1

	-- Получаем предыдущий буфер
	local prev_buf = vim.fn.bufnr('#')

	-- Если предыдущий буфер существует и доступен, переходим к нему
	if prev_buf ~= -1 and vim.fn.buflisted(prev_buf) == 1 then
		vim.cmd('b#') -- Переход к предыдущему буферу

		-- Если текущий буфер можно удалить, закрываем его
		if is_deletable then
			vim.api.nvim_buf_delete(current_buf, { force = true })
		end
	else
		-- Если предыдущего буфера нет, просто выводим сообщение
		vim.notify("Нет предыдущего буфера для перехода", vim.log.levels.WARN)
	end
end, opts)



vim.api.nvim_set_keymap('n', '<leader>lp', ':ShowLumProjects<CR>', { noremap = true })
