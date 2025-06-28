local telescope = require('telescope')
local actions = require('telescope.actions')
local builtin = require('telescope.builtin')

-- Основная настройка Telescope
telescope.setup({
	defaults = {
		file_previewer = require('telescope.previewers').vim_buffer_cat.new({
			preview_limit = 1024 * 1024  -- 1 МБ
		}),
		mappings = {
			i = {
				['<Esc>'] = actions.close,                           -- Закрыть по Esc
				['<A-f>'] = actions.close,                           -- Закрыть по Alt+F (если настроено в терминале)
				['<C-j>'] = actions.move_selection_next,             -- Навигация вниз
				['<C-k>'] = actions.move_selection_previous,         -- Навигация вверх
				['<C-p>'] = actions.cycle_history_prev,              -- История поиска назад
				["<C-l>"] = function(bufnr)
					require("telescope.state").get_status(bufnr).picker.layout_config.scroll_speed = 1
					return require("telescope.actions").preview_scrolling_down(bufnr)
				end,
				["<C-h>"] = function(bufnr)
					require("telescope.state").get_status(bufnr).picker.layout_config.scroll_speed = 1
					return require("telescope.actions").preview_scrolling_up(bufnr)
				end,
			},
		},
		sorting_strategy = 'ascending',                          -- Сортировка сверху
		file_ignore_patterns = {
			"vendor/*",      -- Игнор всей папки vendor
			"node_modules/*", 
			"storage/*",
			"bootstrap/*",
			"public/*",
			"docker/*",
			".git/*",
		},
	},
	pickers = {
		find_files = {
			hidden = true,                                         -- Показывать скрытые файлы
			no_ignore = false,                                    -- Учитывать .gitignore
		},
	},
})

-- Глобальные маппинги
vim.keymap.set('n', '<C-f>', builtin.find_files, { desc = '[F]ind [F]iles' })
-- Редко используемые
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = '[F]ind [H]elp' })
vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = '[F]ind [K]eymaps' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '[F]ind with [G]rep' })

-- Автокоманда для Telescope (опционально)
vim.api.nvim_create_autocmd('FileType', {
	pattern = 'TelescopeResults',
	callback = function()
		vim.opt.cursorline = true                               -- Подсветка текущей строки
	end,
})

vim.keymap.set('n', '<leader>ps', function()
	require('telescope.builtin').grep_string({
		search = 'ERROR:',
		cwd = vim.fn.systemlist('git rev-parse --show-toplevel')[1],
	})
end, { desc = '[P]HP[S]tan Errors' })

vim.keymap.set("n", "<leader>fb", function()  
  builtin.buffers({  
    sort_mru = true,      -- Сначала последние использованные  
    ignore_current = true, -- Показывать текущий буфер  
    previewer = true,      -- Превью содержимого  
    layout_strategy = "horizontal", -- Или "horizontal"  
  })  
end, { desc = "[F]ind [B]uffers (Telescope)" })  
