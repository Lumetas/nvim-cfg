local telescope = require('telescope')
local actions = require('telescope.actions')
local builtin = require('telescope.builtin')

-- Основная настройка Telescope
telescope.setup({
	defaults = {
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
		-- layout_strategy = 'vertical',                            -- Вертикальный layout
		-- layout_config = {
			--   vertical = { width = 0.9, height = 0.95 },
			-- },
			sorting_strategy = 'ascending',                          -- Сортировка сверху
			file_ignore_patterns = {                                 -- Игнорируемые файлы
				'node_modules', '.git', '__pycache__', 'vendor', 'storage'
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

	-- Автокоманда для Telescope (опционально)
	vim.api.nvim_create_autocmd('FileType', {
		pattern = 'TelescopeResults',
		callback = function()
			vim.opt.cursorline = true                               -- Подсветка текущей строки
		end,
	})
