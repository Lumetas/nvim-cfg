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
vim.api.nvim_set_keymap('n', 'zx', ':Yazi<CR>', { noremap = true })

vim.api.nvim_set_keymap('n', '<leader>rr', ':%s/\\v', { noremap = true })
vim.api.nvim_set_keymap('v', '<leader>rr', ':s/\\v', { noremap = true })

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



vim.api.nvim_set_keymap('n', '<leader>lp', ':LumProjectsShow<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>lt', ':LumProjectsTelescope<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>lr', ':LumProjectsRun<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>lb', ':LumProjectsBuild<CR>', { noremap = true })


vim.api.nvim_set_keymap('n', '<leader>f/', ':Telescope current_buffer_fuzzy_find<CR>', { noremap = true , desc = "[F]ind [/] this"})
vim.api.nvim_set_keymap('n', '<leader>ft', ':Telescope treesitter<CR>', { noremap = true , desc = "[F]ind [T]reesitter"})
vim.api.nvim_set_keymap('n', '<leader>fgc', ':Telescope git_commits<CR>', { noremap = true , desc = "[F]ind [G]it [C]ommits"})
vim.api.nvim_set_keymap('n', '<leader>fgb', ':Telescope git_branches<CR>', { noremap = true , desc = "[F]ind [G]it [B]ranches"})
vim.api.nvim_set_keymap('n', '<leader>fls', ':Telescope lsp_document_symbols<CR>', { noremap = true , desc = "[F]ind [L]sp [S]ymbols"})



vim.api.nvim_set_keymap('v', '<leader>el', ':lua<CR>', { noremap = true })


local custom_actions = require("getRelativePath")
vim.keymap.set("i", "<C-f>", function()
  require("telescope.builtin").find_files({
    attach_mappings = function(_, map)
      -- Настройка маппингов только для этого вызова
      map("i", "<CR>", custom_actions.insert_relative_path)
      map("n", "<CR>", custom_actions.insert_relative_path)
      return true
    end
  })
end, {desc = "Вставить относительный путь файла"})

vim.api.nvim_set_keymap('n', '{', ':BufferPrevious<CR>', { noremap = true})
vim.api.nvim_set_keymap('n', '}', ':BufferNext<CR>', { noremap = true})
vim.api.nvim_set_keymap('n', '<Leader>tp', ':BufferPin<CR>', { noremap = true})
vim.api.nvim_set_keymap('n', '<Leader>tc', ':BufferClose<CR>', { noremap = true})
vim.api.nvim_set_keymap('n', '<Leader>w', ':w<CR>', { noremap = true})
vim.api.nvim_set_keymap('n', '<Leader>q', ':q<CR>', { noremap = true})
vim.api.nvim_set_keymap('n', '<Leader>ga', ':G add .<CR>', { noremap = true})
vim.api.nvim_set_keymap('n', '<Leader>gc', ':G commit<CR>', { noremap = true})
vim.api.nvim_set_keymap('n', '<Leader>g', ':G ', { noremap = true})
